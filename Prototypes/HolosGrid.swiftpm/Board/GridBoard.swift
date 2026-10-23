import Foundation
import Observation

/// Scan ids for the parts of the board that are not cells.
enum BoardIDs {
    static let quickRow = "grid.row.quick"
    static let topicsRow = "grid.row.topics"
    static let topicRowOne = "grid.row.topic.1"
    static let topicRowTwo = "grid.row.topic.2"
    static let language = "grid.language"
    static let showMe = "grid.showMe"
    static let cellsPerRow = 5
    /// Space between a scanned row's edge and its cells, room for the ring.
    static let rowPadding: CGFloat = 8
}

/// The topic grid: what is on it, how it scans, and what each choice does.
///
/// The scan is classic row–column, top to bottom:
/// 1. the message row (Speak, Delete last, Clear),
/// 2. quick phrases, spoken at once,
/// 3. the topic tabs, plus a language cell so a switch user can change
///    language without anyone's help,
/// 4–5. the open topic, two rows of five.
///
/// Touch and scanning end in the same methods, so a cell does exactly the
/// same thing however it was reached.
@MainActor
@Observable
final class GridBoard {
    private(set) var topic: Topic = .pain
    private(set) var guide: Guide?
    /// True once a guided step has stalled long enough to offer "Show me".
    private(set) var offersShowMe = false
    let scanner = Scanner()

    /// Something on the board changed (a word added, a topic opened).
    @ObservationIgnored var onChange: (() -> Void)?
    /// A message was spoken, with the cells it was made of.
    @ObservationIgnored var onSpoken: (([Phrase]) -> Void)?
    @ObservationIgnored var onShowMe: (() -> Void)?
    @ObservationIgnored private let services: HolosServices
    /// What the Speaker said the last time this board spoke by itself (a
    /// quick phrase, or a scanned Speak), so the speech watcher does not
    /// take the board's own words for a tap on the message bar's Speak.
    @ObservationIgnored private var ownUtterance: String?

    init(services: HolosServices) {
        self.services = services
        bindScanner()
    }

    /// Core's Speaker has a single "message finished" hook, and the scanner
    /// bound last owns it. The closing choices and the head-turn panel bind
    /// their own scanners, so the board binds again every time it goes
    /// live — otherwise auditory prompts would stop re-announcing the lit
    /// cell after a message once the tour had moved past step 3.
    private func bindScanner() {
        scanner.bind(
            to: services,
            label: { [weak self] id in self?.label(for: id) },
            onSelect: { [weak self] id in self?.select(id) }
        )
    }

    var firstRow: [Phrase] { Array(topic.phrases.prefix(BoardIDs.cellsPerRow)) }
    var secondRow: [Phrase] { Array(topic.phrases.dropFirst(BoardIDs.cellsPerRow)) }

    /// Where the "Next" tag belongs right now, if a step is guiding.
    var guideTarget: GuideTarget? {
        guide?.target(message: services.message.phrases, topic: topic)
    }

    // MARK: - Set-up

    /// Sets the goal (or none) and, optionally, the open topic.
    func configure(guide: Guide?, topic: Topic? = nil) {
        self.guide = guide
        offersShowMe = false
        if let topic {
            self.topic = topic
        }
        reloadIfRunning()
    }

    func offerShowMe() {
        guard !offersShowMe else { return }
        offersShowMe = true
        reloadIfRunning()
    }

    func startScanning() {
        guard scanner.state == .stopped else { return }
        // After the guard: binding a scan that is already running would
        // re-announce its lit item at once.
        bindScanner()
        scanner.load(tree())
    }

    func stopScanning() {
        guard scanner.state != .stopped else { return }
        scanner.stop()
    }

    // MARK: - The scan

    /// The rows, top to bottom.
    ///
    /// Right after a topic is chosen the same rows are rotated so the scan
    /// starts on the topic's first row: the person has just said "this
    /// topic", and making them wait through the message and quick rows
    /// again would waste two or three steps every time. The order around the
    /// loop never changes, only where it starts.
    func tree(startingAtTopicRows: Bool = false) -> [ScanNode] {
        let quickItems: [ScanNode] = Vocabulary.quick.map { ScanNode.item($0.id) }
        let topicItems: [ScanNode] = Topic.allCases.map { ScanNode.item($0.scanID) } + [ScanNode.item(BoardIDs.language)]
        let rowOne: [ScanNode] = firstRow.map { ScanNode.item($0.id) }
        let rowTwo: [ScanNode] = secondRow.map { ScanNode.item($0.id) }
        var rows: [ScanNode] = [
            MessageBar.scanRow,
            ScanNode.group(BoardIDs.quickRow, quickItems),
            ScanNode.group(BoardIDs.topicsRow, topicItems),
            ScanNode.group(BoardIDs.topicRowOne, rowOne),
            ScanNode.group(BoardIDs.topicRowTwo, rowTwo),
        ]
        if startingAtTopicRows {
            rows = Array(rows.dropFirst(3)) + Array(rows.prefix(3))
        }
        if offersShowMe {
            rows.insert(ScanNode.item(BoardIDs.showMe), at: 0)
        }
        return rows
    }

    /// Words for auditory prompts.
    func label(for id: String) -> Bilingual? {
        if let words = MessageBar.label(for: id) { return words }
        switch id {
        case BoardIDs.quickRow: return Copy.quickRow
        case BoardIDs.topicsRow: return Copy.topicsRow
        case BoardIDs.topicRowOne: return Copy.topicRow(topic, 1)
        case BoardIDs.topicRowTwo: return Copy.topicRow(topic, 2)
        case BoardIDs.language: return CoreCopy.languageLabel
        case BoardIDs.showMe: return Copy.showMe
        default: break
        }
        if let topic = Topic(scanID: id) { return topic.name }
        return Vocabulary.phrase(id: id)?.label
    }

    /// A scanned choice. `Scanner.bind` has already given the select feel.
    private func select(_ id: String) {
        if id == BoardIDs.showMe {
            onShowMe?()
            return
        }
        if MessageBar.perform(id, services: services) {
            if id == MessageBar.speakID, !services.message.isEmpty {
                ownUtterance = services.speaker.currentText
                onSpoken?(services.message.phrases)
            }
            finishSelection()
            return
        }
        if id == BoardIDs.language {
            switchLanguage()
            finishSelection()
            return
        }
        if let chosen = Topic(scanID: id) {
            topic = chosen
            finishSelection(startingAtTopicRows: true)
            return
        }
        if let quickPhrase = Vocabulary.quick.first(where: { $0.id == id }) {
            speakQuick(quickPhrase)
            finishSelection()
            return
        }
        if let phrase = topic.phrases.first(where: { $0.id == id }) {
            if !services.message.add(phrase) {
                services.feedback.unavailable()
            }
            finishSelection()
        }
    }

    /// The scanner has already gone back to the top of whatever tree it
    /// holds; reloading puts it on the canonical one (or the rotated one
    /// after a topic), unless the step has just stopped the scan.
    private func finishSelection(startingAtTopicRows: Bool = false) {
        reloadIfRunning(startingAtTopicRows: startingAtTopicRows)
        onChange?()
    }

    private func reloadIfRunning(startingAtTopicRows: Bool = false) {
        guard scanner.state != .stopped else { return }
        scanner.load(tree(startingAtTopicRows: startingAtTopicRows))
    }

    // MARK: - Touch

    func tapCell(_ phrase: Phrase) {
        if services.message.add(phrase) {
            services.feedback.select()
        } else {
            services.feedback.unavailable()
        }
        onChange?()
    }

    func tapQuick(_ phrase: Phrase) {
        speakQuick(phrase)
        onChange?()
    }

    func tapTopic(_ chosen: Topic) {
        services.feedback.enter()
        topic = chosen
        onChange?()
    }

    func tapLanguage() {
        services.feedback.select()
        switchLanguage()
    }

    func tapShowMe() {
        services.feedback.select()
        onShowMe?()
    }

    // MARK: - Speech

    /// Told whenever the Speaker starts a message, from any source. Only
    /// the message bar's own Speak *button* is not routed through this
    /// board, so this catches it by recognising the message being spoken.
    ///
    /// The board's own speech is skipped. Step 2 can turn a quick "I’m in
    /// pain" into the first word of the message; without this, that phrase
    /// would then look like the message being spoken and end the step.
    func speechStarted(_ text: String) {
        if text == ownUtterance {
            ownUtterance = nil
            return
        }
        guard !services.message.isEmpty, Self.matches(services.message.words, text) else { return }
        onSpoken?(services.message.phrases)
    }

    /// The Speaker went quiet: whatever the board said last is over.
    func speechEnded() {
        ownUtterance = nil
    }

    private func speakQuick(_ phrase: Phrase) {
        services.feedback.speak()
        services.speaker.say(phrase.speech)
        ownUtterance = services.speaker.currentText
        onSpoken?([phrase])
    }

    private func switchLanguage() {
        services.settings.language = services.settings.language.other
    }

    /// The Speaker trims and may fall back to English, so compare against
    /// every form the words could have been spoken in.
    private static func matches(_ words: Bilingual, _ text: String) -> Bool {
        for language in Language.allCases {
            for gender in SpeakerGender.allCases where words(language, gender) == text {
                return true
            }
        }
        return false
    }
}
