import Foundation
import Observation

/// Scan ids for the parts of the whole board that are not cells.
enum GridIDs {
    static let quickRow = "grid.row.quick"
    static let topicsRow = "grid.row.topics"
    static let topicRowOne = "grid.row.topic.1"
    static let topicRowTwo = "grid.row.topic.2"
    static let language = "grid.language"
    static let showMe = "grid.showMe"
    /// "Back to the answers", offered while a question waits for its answer.
    static let back = "grid.back"
    static let cellsPerRow = 5
    /// Space between a scanned row's edge and its cells, room for the ring.
    static let rowPadding: CGFloat = 8
}

/// The whole board — Holos Grid's topic grid — that "Something else" opens
/// and that free conversation starts from: what is on it, how it scans, and
/// what each choice does.
///
/// The scan is classic row–column, top to bottom:
/// 1. the message row (Speak, Delete last, Clear),
/// 2. quick phrases, spoken at once,
/// 3. the topic tabs, plus a language cell so a switch user can change
///    language without anyone's help,
/// 4–5. the open topic, two rows of five,
/// 6. "Back to the answers", while a question is waiting.
///
/// It has its own scanner, as it does in Holos Grid; the conversation
/// screen routes the switch to it while the whole board is showing. Touch
/// and scanning end in the same methods, so a cell does exactly the same
/// thing however it was reached.
@MainActor
@Observable
final class GridBoard {
    private(set) var topic: Topic = .needs
    private(set) var guide: Guide?
    /// True once a guided turn has stalled long enough to offer "Show me".
    private(set) var offersShowMe = false
    /// True while a question waits, so there are answers to go back to.
    private(set) var offersBack = false
    let scanner = Scanner()

    /// Something was said: a whole message (`fromMessage`), or one quick
    /// phrase, which never touches the message.
    @ObservationIgnored var onSpoken: (([Phrase], Bool) -> Void)?
    @ObservationIgnored var onShowMe: (() -> Void)?
    @ObservationIgnored var onBack: (() -> Void)?
    /// A topic was opened or a word added: progress, so a guided turn's
    /// "Show me" clock can start again.
    @ObservationIgnored var onProgress: (() -> Void)?
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
    /// bound last owns it. The answers and the head-turn panel bind their
    /// own scanners, so the board binds again every time it goes live.
    private func bindScanner() {
        scanner.bind(
            to: services,
            label: { [weak self] id in self?.label(for: id) },
            onSelect: { [weak self] id in self?.select(id) }
        )
    }

    var firstRow: [Phrase] { Array(topic.phrases.prefix(GridIDs.cellsPerRow)) }
    var secondRow: [Phrase] { Array(topic.phrases.dropFirst(GridIDs.cellsPerRow)) }

    /// Where the guide's tag belongs right now, if a turn is guiding here.
    var guideTarget: GuideTarget? {
        guide?.target(message: services.message.phrases, topic: topic)
    }

    /// The row that holds `target`. While scanning, the next press there
    /// picks the row, so the tag sits on the row until the scan is inside.
    func rowID(holding target: GuideTarget) -> String {
        switch target {
        case .speak:
            MessageBar.rowID
        case .topic:
            GridIDs.topicsRow
        case .cell(let phrase, _):
            firstRow.contains { $0.id == phrase.id } ? GridIDs.topicRowOne : GridIDs.topicRowTwo
        }
    }

    // MARK: - Set-up

    /// Sets the goal (or none), the open topic, and whether there are
    /// answers to go back to. Always the same first topic, so the board is
    /// learnable: Needs is where most bedside requests live.
    func configure(guide: Guide?, topic: Topic = .needs, offersBack: Bool) {
        self.guide = guide
        self.topic = topic
        self.offersBack = offersBack
        offersShowMe = false
        reloadIfRunning()
    }

    func offerShowMe() {
        guard !offersShowMe else { return }
        offersShowMe = true
        reloadIfRunning()
    }

    /// Progress takes the offer back: the "Show me" clock starts again.
    func withdrawShowMe() {
        guard offersShowMe else { return }
        offersShowMe = false
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
        let quickItems: [ScanNode] = BoardVocabulary.quick.map { ScanNode.item($0.id) }
        let topicItems: [ScanNode] = Topic.allCases.map { ScanNode.item($0.scanID) } + [ScanNode.item(GridIDs.language)]
        let rowOne: [ScanNode] = firstRow.map { ScanNode.item($0.id) }
        let rowTwo: [ScanNode] = secondRow.map { ScanNode.item($0.id) }
        var rows: [ScanNode] = [
            MessageBar.scanRow,
            ScanNode.group(GridIDs.quickRow, quickItems),
            ScanNode.group(GridIDs.topicsRow, topicItems),
            ScanNode.group(GridIDs.topicRowOne, rowOne),
            ScanNode.group(GridIDs.topicRowTwo, rowTwo),
        ]
        if offersBack {
            rows.append(ScanNode.item(GridIDs.back))
        }
        if startingAtTopicRows {
            rows = Array(rows.dropFirst(3)) + Array(rows.prefix(3))
        }
        if offersShowMe {
            rows.insert(ScanNode.item(GridIDs.showMe), at: 0)
        }
        return rows
    }

    /// Words for auditory prompts.
    func label(for id: String) -> Bilingual? {
        if let words = MessageBar.label(for: id) { return words }
        switch id {
        case GridIDs.quickRow: return Copy.quickRow
        case GridIDs.topicsRow: return Copy.topicsRow
        case GridIDs.topicRowOne: return Copy.topicRow(topic, 1)
        case GridIDs.topicRowTwo: return Copy.topicRow(topic, 2)
        case GridIDs.language: return CoreCopy.languageLabel
        case GridIDs.showMe: return Copy.showMe
        case GridIDs.back: return Copy.backToAnswers
        default: break
        }
        if let topic = Topic(scanID: id) { return topic.name }
        return BoardVocabulary.phrase(id: id)?.label
    }

    /// A scanned choice. `Scanner.bind` has already given the select feel.
    private func select(_ id: String) {
        if id == GridIDs.showMe {
            onShowMe?()
            return
        }
        if id == GridIDs.back {
            onBack?()
            return
        }
        if MessageBar.perform(id, services: services) {
            if id == MessageBar.speakID, !services.message.isEmpty {
                ownUtterance = services.speaker.currentText
                onSpoken?(services.message.phrases, true)
            }
            finishSelection()
            return
        }
        if id == GridIDs.language {
            switchLanguage()
            finishSelection()
            return
        }
        if let chosen = Topic(scanID: id) {
            topic = chosen
            onProgress?()
            finishSelection(startingAtTopicRows: true)
            return
        }
        if let quickPhrase = BoardVocabulary.quick.first(where: { $0.id == id }) {
            speakQuick(quickPhrase)
            finishSelection()
            return
        }
        if let phrase = topic.phrases.first(where: { $0.id == id }) {
            if services.message.add(phrase) {
                onProgress?()
            } else {
                services.feedback.unavailable()
            }
            finishSelection()
        }
    }

    /// The scanner has already gone back to the top of whatever tree it
    /// holds; reloading puts it on the canonical one (or the rotated one
    /// after a topic), unless the conversation has just stopped the scan.
    private func finishSelection(startingAtTopicRows: Bool = false) {
        reloadIfRunning(startingAtTopicRows: startingAtTopicRows)
    }

    private func reloadIfRunning(startingAtTopicRows: Bool = false) {
        guard scanner.state != .stopped else { return }
        scanner.load(tree(startingAtTopicRows: startingAtTopicRows))
    }

    // MARK: - Touch

    func tapCell(_ phrase: Phrase) {
        if services.message.add(phrase) {
            services.feedback.select()
            onProgress?()
        } else {
            services.feedback.unavailable()
        }
    }

    func tapQuick(_ phrase: Phrase) {
        speakQuick(phrase)
    }

    func tapTopic(_ chosen: Topic) {
        services.feedback.enter()
        topic = chosen
        onProgress?()
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
    /// The board's own speech is skipped.
    func speechStarted(_ text: String) {
        if text == ownUtterance {
            ownUtterance = nil
            return
        }
        guard !services.message.isEmpty, Self.matches(services.message.words, text) else { return }
        onSpoken?(services.message.phrases, true)
    }

    /// The Speaker went quiet: whatever the board said last is over.
    func speechEnded() {
        ownUtterance = nil
    }

    private func speakQuick(_ phrase: Phrase) {
        services.feedback.speak()
        services.speaker.say(phrase.speech)
        ownUtterance = services.speaker.currentText
        onSpoken?([phrase], false)
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
