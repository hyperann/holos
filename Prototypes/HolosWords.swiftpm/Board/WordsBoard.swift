import Foundation
import Observation

/// The board's state: which starter is open, what Find a word has narrowed
/// to, and what the scan should offer next.
///
/// The whole concept is two choices per sentence. So the scan follows the
/// sentence, not the screen: once a starter opens a blank, the scan jumps
/// straight to the words that fit it; once a sentence is finished, it
/// starts at the sentence bar, where Speak is. The rows never move on
/// screen — only where the highlight starts changes, which saves a full
/// row's wait on every choice a switch user makes.
@MainActor
@Observable
final class WordsBoard {
    /// What the guided steps of the tour ask the person to say.
    enum Goal: Equatable, Sendable {
        case feelPainNeedMedicine
        case callWife
    }

    /// The next thing to choose towards the goal, marked on screen with a
    /// small "Next" tag and done for you by "Show me".
    enum Target: Equatable, Sendable {
        case starter(FrameID)
        case filler(String)
        case findOpen
        case findOption(String)
        case findBack
        case speak
    }

    /// The starter whose words are on the board.
    private(set) var shownFrame: FrameID = .need
    /// Set while a starter waits for its word: the sentence bar shows a blank.
    private(set) var pendingFrame: FrameID?
    /// Find a word's screens, root first. Empty when Find a word is closed.
    private(set) var trail: [FindCategory] = []
    private(set) var goal: Goal?
    /// After `stallSeconds` without progress, "Show me" and "Skip" appear
    /// and stay for the rest of the step.
    private(set) var helpOffered = false
    /// Bumps each time a sentence lands in the bar, so the bar can glow.
    private(set) var addedCount = 0

    let scanner = Scanner()

    /// Set by the tour: told about every message spoken.
    @ObservationIgnored var onSpoke: (([Phrase]) -> Void)?
    /// Set by the tour: "Skip this step".
    @ObservationIgnored var onSkip: (() -> Void)?

    @ObservationIgnored private var services: HolosServices?
    @ObservationIgnored private var scanActive = false
    /// True from `connect` to `leave`. Off screen there is no one to rescue,
    /// so the stall timer never runs and "Stuck?" is never announced over
    /// a different screen — whatever rebuilds the board meanwhile.
    @ObservationIgnored private var isOnScreen = false
    @ObservationIgnored private var lastTarget: Target?
    @ObservationIgnored private var stallTask: Task<Void, Never>?

    /// Long enough to read, try and get it wrong twice; short enough that
    /// a judge who is lost is rescued well inside three minutes.
    static let stallSeconds: Double = 45

    init() {}

    // MARK: - Reading

    var frame: SentenceFrame { Vocabulary.frame(shownFrame) }
    var findScreen: FindCategory? { trail.last }
    var isFinding: Bool { !trail.isEmpty }
    /// The blank shows while a starter waits for its word — and while
    /// finding, so the person keeps the sentence they are completing in view.
    var showsBlank: Bool { pendingFrame != nil || isFinding }

    /// The fillers in two rows of four.
    var fillerRows: [[Phrase]] {
        let fillers = frame.fillers
        return [Array(fillers.prefix(4)), Array(fillers.dropFirst(4).prefix(4))].filter { !$0.isEmpty }
    }

    var isVoiceBusy: Bool { services?.speaker.isSpeaking ?? false }

    /// The sentence a Find a word answer would make right now.
    func resolved(_ concept: String, home: FrameID) -> (frame: FrameID, phrase: Phrase)? {
        Vocabulary.resolve(concept, preferring: shownFrame, home: home)
    }

    private var said: [Phrase] { services?.message.phrases ?? [] }

    // MARK: - Wiring

    /// Called by the board screen whenever it appears.
    func connect(_ services: HolosServices) {
        self.services = services
        isOnScreen = true
        // Bound before any load, so the first lit item is announced too.
        scanner.bind(to: services, label: { [weak self] id in
            self?.label(for: id)
        }, onSelect: { [weak self] id in
            self?.select(id)
        })
    }

    /// Scanning runs only while the board is on screen and the person is
    /// in scanning mode (not touch, VoiceOver or Switch Control).
    func setScanActive(_ active: Bool) {
        scanActive = active
        rebuild()
    }

    /// The board left the screen: stop scanning, and stop the stall timer
    /// so "Stuck?" is never announced over a different screen. The timer
    /// starts afresh when the board comes back.
    ///
    /// The order matters. The rebuild inside `setScanActive` runs the guide,
    /// which would re-arm the very timer this is here to stop — so the board
    /// is marked off screen first, and the timer is cancelled after it.
    func leave() {
        isOnScreen = false
        setScanActive(false)
        stallTask?.cancel()
        stallTask = nil
        lastTarget = nil
    }

    /// A fresh board for a step of the tour, or for free use (`nil`).
    func begin(goal: Goal?) {
        self.goal = goal
        helpOffered = false
        pendingFrame = nil
        trail = []
        shownFrame = .need
        services?.message.clear()
        lastTarget = nil
        stallTask?.cancel()
        stallTask = nil
        rebuild()
    }

    // MARK: - Choosing

    /// A direct touch. The scan's own selections already played their
    /// feedback in `Scanner.bind`; a tap plays the same, then does the same.
    func tap(_ id: String) {
        services?.feedback.select()
        select(id)
    }

    private func select(_ id: String) {
        switch id {
        case ScanID.speak: speak()
        case ScanID.delete: deleteLast()
        case ScanID.clearCancel:
            // "No, keep it": the message stays as it is. The scanner has
            // already gone back to the top, and the selection's own feedback
            // has said the press landed, so there is nothing to rebuild.
            break
        case ScanID.clear, ScanID.clearConfirm: clearAll()
        case ScanID.language: toggleLanguage()
        case ScanID.findOpen: openFind()
        case ScanID.findBack: findBack()
        case ScanID.showMe: showMe()
        case ScanID.skip: onSkip?()
        default:
            if let raw = id.dropping(prefix: ScanID.starterPrefix), let frameID = FrameID(rawValue: raw) {
                chooseStarter(frameID)
            } else if let phraseID = id.dropping(prefix: ScanID.fillerPrefix) {
                chooseFiller(phraseID)
            } else if id.hasPrefix(ScanID.findOptionPrefix) {
                chooseFindOption(id)
            }
        }
    }

    private func chooseStarter(_ frameID: FrameID) {
        shownFrame = frameID
        pendingFrame = frameID
        trail = []
        rebuild()
        tellVoiceOver(Copy.withBlank(Vocabulary.frame(frameID).stem))
    }

    private func chooseFiller(_ phraseID: String) {
        guard let phrase = frame.fillers.first(where: { $0.id == phraseID }) ?? Vocabulary.phrase(id: phraseID) else { return }
        add(phrase, from: phrase.frameID ?? shownFrame)
    }

    private func add(_ phrase: Phrase, from frameID: FrameID) {
        guard let services else { return }
        guard services.message.add(phrase) else {
            // Full: say so gently rather than pretend it worked.
            services.feedback.unavailable()
            return
        }
        shownFrame = frameID
        pendingFrame = nil
        trail = []
        addedCount += 1
        rebuild()
        tellVoiceOver(Copy.added(phrase.speech))
    }

    private func deleteLast() {
        guard let services else { return }
        if pendingFrame != nil {
            // Undo the most recent choice first: the open blank.
            pendingFrame = nil
        } else if services.message.isEmpty {
            services.feedback.unavailable()
            return
        } else {
            services.message.removeLast()
        }
        rebuild()
    }

    private func clearAll() {
        pendingFrame = nil
        trail = []
        services?.message.clear()
        services?.speaker.stop()
        rebuild()
    }

    private func speak() {
        guard let services else { return }
        guard !services.message.isEmpty else {
            services.feedback.unavailable()
            return
        }
        MessageBar.speakMessage(services: services)
        onSpoke?(services.message.phrases)
    }

    private func toggleLanguage() {
        guard let settings = services?.settings else { return }
        settings.language = settings.language.other
        announce(settings.language.nativeName, in: settings.language)
    }

    // MARK: - Find a word

    private func openFind() {
        trail = [FindTree.root]
        rebuild()
        tellVoiceOver(FindTree.root.question)
    }

    private func findBack() {
        if trail.count > 1 {
            trail.removeLast()
        } else {
            trail = []
        }
        rebuild()
        if let screen = trail.last {
            tellVoiceOver(screen.question)
        }
    }

    private func chooseFindOption(_ scanID: String) {
        guard let screen = trail.last,
              let option = screen.options.first(where: { ScanID.findOption($0) == scanID })
        else { return }
        switch option {
        case .category(let category):
            trail.append(category)
            rebuild()
            tellVoiceOver(category.question)
        case .word(let concept, let home):
            guard let found = resolved(concept, home: home) else {
                services?.feedback.unavailable()
                return
            }
            add(found.phrase, from: found.frame)
        }
    }

    // MARK: - The scan

    private func rebuild() {
        scanner.load(scanTree(), start: scanActive)
        refreshGuide()
    }

    private func scanTree() -> [ScanNode] {
        var nodes: [ScanNode] = []
        if goal != nil, helpOffered {
            // First, so a stuck person reaches them with one press.
            nodes.append(ScanNode.item(ScanID.showMe))
            nodes.append(ScanNode.item(ScanID.skip))
        }

        // Find a word scans linearly: a few big answers and Back.
        if let screen = trail.last {
            nodes += screen.options.map { ScanNode.item(ScanID.findOption($0)) }
            nodes.append(ScanNode.item(ScanID.findBack))
            return nodes
        }

        let sentence = ScanNode.group(ScanID.sentenceRow, [
            ScanNode.item(ScanID.speak),
            ScanNode.item(ScanID.delete),
            // "No, keep it" first, so a double press keeps the message.
            ScanNode.group(ScanID.clear, [ScanNode.item(ScanID.clearCancel), ScanNode.item(ScanID.clearConfirm)]),
        ])
        let starters = ScanNode.group(
            ScanID.startersRow,
            FrameID.allCases.map { ScanNode.item(ScanID.starter($0)) } + [ScanNode.item(ScanID.language)]
        )
        var fillers: [ScanNode] = []
        for (index, row) in fillerRows.enumerated() {
            fillers.append(ScanNode.group(ScanID.fillerRow(index), row.map { ScanNode.item(ScanID.filler($0.id)) }))
        }
        let find = ScanNode.item(ScanID.findOpen)

        if pendingFrame != nil {
            // A blank is open: its words first.
            nodes += fillers + [find, starters, sentence]
        } else if !said.isEmpty {
            // A sentence is finished: Speak, or start the next one.
            nodes += [sentence, starters] + fillers + [find]
        } else {
            // Nothing yet: nothing to speak, so start at the starters.
            nodes += [starters] + fillers + [find, sentence]
        }
        return nodes
    }

    private func label(for id: String) -> Bilingual? {
        switch id {
        case ScanID.sentenceRow: return Copy.sentenceRow
        case ScanID.speak: return CoreCopy.speak
        case ScanID.delete: return CoreCopy.deleteLast
        case ScanID.clear: return CoreCopy.clear
        case ScanID.clearCancel: return CoreCopy.clearCancel
        case ScanID.clearConfirm: return CoreCopy.clearConfirm
        case ScanID.startersRow: return Copy.startersRow
        case ScanID.language: return Copy.languageCell
        case ScanID.findOpen: return Copy.findWord
        case ScanID.findBack: return CoreCopy.goBack
        case ScanID.showMe: return Copy.showMe
        case ScanID.skip: return Copy.skipStep
        default: break
        }
        if id.hasPrefix(ScanID.fillerRowPrefix) {
            return Copy.wordsRow
        }
        if let raw = id.dropping(prefix: ScanID.starterPrefix), let frameID = FrameID(rawValue: raw) {
            return Vocabulary.frame(frameID).starter
        }
        if let phraseID = id.dropping(prefix: ScanID.fillerPrefix) {
            return Vocabulary.phrase(id: phraseID)?.label
        }
        if let option = trail.last?.options.first(where: { ScanID.findOption($0) == id }) {
            switch option {
            case .category(let category):
                return category.label
            case .word(let concept, let home):
                return resolved(concept, home: home)?.phrase.label
            }
        }
        return nil
    }

    private func tellVoiceOver(_ words: Bilingual) {
        guard let settings = services?.settings else { return }
        announce(words(settings.language, settings.gender), in: settings.language)
    }

    // MARK: - The guide

    /// The next choice towards the goal, computed from what is on the board
    /// right now — so a wrong turn is never punished, only re-routed.
    var target: Target? {
        guard let goal else { return nil }
        switch goal {
        case .feelPainNeedMedicine:
            return nextTarget(toSay: [Phrase.makeID(.feel, "pain"), Phrase.makeID(.need, "medicine")])
        case .callWife:
            return callWifeTarget()
        }
    }

    private func nextTarget(toSay ids: [String]) -> Target {
        let saidIDs = Set(said.map(\.id))
        for id in ids where !saidIDs.contains(id) {
            if isFinding { return .findBack }
            guard let frameID = Vocabulary.phrase(id: id)?.frameID else { continue }
            return shownFrame == frameID ? .filler(id) : .starter(frameID)
        }
        return speakOrLeaveFind
    }

    private func callWifeTarget() -> Target {
        if said.contains(where: { $0.id == Phrase.makeID(.call, "wife") }) { return speakOrLeaveFind }
        // Person › Family › My generation › Wife — the route the step teaches.
        let route = [FindTree.person.id, FindTree.family.id, FindTree.sameAge.id]
        if isFinding {
            let taken = trail.dropFirst().map(\.id)
            guard taken.count <= route.count, Array(route.prefix(taken.count)) == taken else { return .findBack }
            if taken.count < route.count {
                return .findOption(ScanID.findCategory(route[taken.count]))
            }
            return .findOption(ScanID.findWord("wife"))
        }
        return shownFrame == .call ? .findOpen : .starter(.call)
    }

    /// Everything needed has been said, so Speak is next — unless Find a
    /// word is open while scanning. Then Speak is not in the scan at all,
    /// and the tag goes on Back, the way to reach it. A finger can tap
    /// Speak above the Find panel directly, so touch keeps the shorter way.
    /// (`scanActive` is not observed, but every change to it rebuilds the
    /// scan, which redraws every view that reads `target`.)
    private var speakOrLeaveFind: Target {
        isFinding && scanActive ? .findBack : .speak
    }

    /// Restarts the stall timer whenever the target moves on: progress,
    /// not pressing, is what counts.
    private func refreshGuide() {
        guard isOnScreen else {
            // Nothing to rescue off screen. Forgetting the target means the
            // timer starts afresh, from zero, when the board comes back.
            stallTask?.cancel()
            stallTask = nil
            lastTarget = nil
            return
        }
        let now = target
        guard now != lastTarget else { return }
        lastTarget = now
        stallTask?.cancel()
        stallTask = nil
        guard goal != nil, !helpOffered else { return }
        stallTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(WordsBoard.stallSeconds))
            guard !Task.isCancelled else { return }
            self?.offerHelp()
        }
    }

    private func offerHelp() {
        guard goal != nil, !helpOffered, isOnScreen else { return }
        helpOffered = true
        rebuild()
        tellVoiceOver(Copy.helpOffered)
    }

    private func showMe() {
        guard let next = target else { return }
        switch next {
        case .starter(let frameID): chooseStarter(frameID)
        case .filler(let id): chooseFiller(id)
        case .findOpen: openFind()
        case .findOption(let id): chooseFindOption(id)
        case .findBack: findBack()
        case .speak: speak()
        }
    }
}
