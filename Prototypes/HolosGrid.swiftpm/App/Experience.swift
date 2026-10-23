import Foundation
import Observation

/// Owns the tour: which step is showing, what one press means right now,
/// and when a step is finished. Screens only draw what it says.
///
/// Every switch press in the app arrives here first (`press(_:)`), which is
/// how one switch can drive narrative screens, the board and the closing
/// choice alike — each screen is just a different answer to "what does a
/// press do now?".
@MainActor
@Observable
final class Experience {
    static let keepTalkingID = "closing.keepTalking"
    static let startAgainID = "closing.startAgain"

    private(set) var step: FlowStep = .problem
    private(set) var phase: FlowPhase = .intro
    /// Step 1: which nurse line is showing, and whether Holos has been named.
    private(set) var nurseLine = 0
    private(set) var problemRevealed = false
    /// The hub's press count when the guided scan began, so a step can
    /// show "Presses: 5" for its own presses only.
    private(set) var pressBaseline = 0
    private(set) var finalPresses: Int?
    /// What the person just said, for the success card.
    private(set) var spokenWords: Bilingual?
    /// The cells it was made of, so the card claims only what was done.
    private(set) var spokenPhrases: [Phrase] = []
    /// True when "Show me" built the message rather than the person.
    private(set) var usedShowMe = false
    /// Step 2's message, replayed in Ukrainian in step 4.
    private(set) var firstMessage: [Phrase] = Vocabulary.goalOne.phrases
    /// The language to narrate in. Step 4 switches the board to Ukrainian,
    /// but its explanation stays in the judge's own language — Ukrainian is
    /// the thing being shown, never something they must read to go on.
    private(set) var narrationLanguage: Language?
    /// Whether presses go to a scan (`true`) or cells are touched. Reported
    /// by the root view, which can see VoiceOver and Switch Control.
    var modeIsScanning = true {
        didSet {
            if modeIsScanning != oldValue { refreshScanning() }
        }
    }

    let services: HolosServices
    let board: GridBoard
    /// The closing screen's two choices, scanned like everything else.
    let choices = Scanner()

    /// Off for previews, so a preview of step 4 never leaves a marker behind
    /// (see `Experience+Language.swift`).
    let persistsTourState: Bool
    @ObservationIgnored private var gateOpensAt = Date.distantPast
    @ObservationIgnored private var revealDue = Date.distantFuture
    @ObservationIgnored private var lastTarget: GuideTarget?
    @ObservationIgnored private var stuckTask: Task<Void, Never>?
    @ObservationIgnored private var revealTask: Task<Void, Never>?
    @ObservationIgnored private var speakTask: Task<Void, Never>?
    @ObservationIgnored private var announceTask: Task<Void, Never>?
    @ObservationIgnored private var hasStarted = false

    /// Long enough for a deliberate second try, short enough that a stuck
    /// judge is offered help well inside the three minutes.
    private static let stuckSeconds = 45.0
    /// Step 1 names Holos by itself after this long if nobody presses at all.
    private static let revealIfNobodyPresses = 20.0

    init(services: HolosServices, persistsTourState: Bool = true) {
        self.services = services
        self.persistsTourState = persistsTourState
        board = GridBoard(services: services)
        board.onChange = { [weak self] in self?.boardChanged() }
        board.onSpoken = { [weak self] phrases in self?.spoken(phrases) }
        board.onShowMe = { [weak self] in self?.showMe() }
        bindChoices()
    }

    /// The language narrative text is written in right now.
    var language: Language { narrationLanguage ?? services.settings.language }

    // MARK: - Entry points

    /// Called when the window appears. Safe to call again.
    func start() {
        claimSwitch()
        guard !hasStarted else { return }
        hasStarted = true
        returnBorrowedLanguage()
        enter(.problem)
    }

    /// Routes every press here. Also used after the head-turn panel, which
    /// borrows the switch while it is on screen.
    func claimSwitch() {
        services.hub.route { [weak self] source in
            self?.press(source)
        }
    }

    func headTryFinished() {
        claimSwitch()
        guard step == .aphasia else { return }
        advance()
    }

    func keepTalking() {
        enter(.free)
    }

    func restart() {
        enter(.problem)
    }

    /// One press, whatever it came from.
    func press(_ source: SwitchSource) {
        switch step {
        case .problem:
            pressOnProblem()
        case .oneSwitch, .aphasia:
            switch phase {
            case .intro:
                guard gateIsOpen else { return }
                beginWorking()
            case .working:
                board.scanner.press()
            case .done:
                if step == .oneSwitch {
                    continueFlow()
                } else {
                    // Step 3's payoff gets its own screen and its own read
                    // gate; only then does the head-turn invitation appear.
                    guard gateIsOpen else { return }
                    services.feedback.select()
                    phase = .headTry
                }
            case .headTry:
                // Core's panel routes the switch itself while it is shown;
                // a press that lands before it appears does nothing.
                return
            }
        case .ukrainian:
            continueFlow()
        case .closing:
            guard gateIsOpen else { return }
            if modeIsScanning, choices.state == .stopped {
                // The choices wait for a press that says "I have read this",
                // so a press made after reading never lands on whichever of
                // "Keep talking" and "Start again" happens to be lit.
                services.feedback.enter()
                choices.start()
            } else {
                choices.press()
            }
        case .free:
            board.scanner.press()
        }
    }

    // MARK: - Steps

    private func enter(_ next: FlowStep) {
        stuckTask?.cancel()
        revealTask?.cancel()
        speakTask?.cancel()
        announceTask?.cancel()
        if step == .ukrainian, next != .ukrainian, let previous = narrationLanguage {
            services.settings.language = previous
            forgetBorrowedLanguage()
        }
        narrationLanguage = nil
        step = next
        phase = .intro
        finalPresses = nil
        spokenWords = nil
        spokenPhrases = []
        usedShowMe = false
        lastTarget = nil
        // An accidental double press must never skip a screen unread.
        closeGate(for: 0.9)

        switch next {
        case .problem:
            nurseLine = 0
            problemRevealed = false
            services.message.clear()
            board.configure(guide: nil, topic: .pain)
            revealDue = .distantFuture
            revealWithin(Self.revealIfNobodyPresses)
        case .oneSwitch:
            firstMessage = Vocabulary.goalOne.phrases
            services.message.clear()
            board.configure(guide: Vocabulary.goalOne, topic: .pain)
        case .aphasia:
            services.message.clear()
            board.configure(guide: Vocabulary.goalTwo)
        case .ukrainian:
            let borrowed = services.settings.language
            narrationLanguage = borrowed
            rememberBorrowedLanguage(borrowed)
            services.settings.language = .ukrainian
            board.configure(guide: nil)
            services.message.clear()
            for phrase in firstMessage {
                services.message.add(phrase)
            }
            closeGate(for: 2.0)
            // A beat for the board to turn Ukrainian before it speaks.
            speakTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled, let self else { return }
                self.services.feedback.speak()
                self.services.speaker.say(self.services.message.words)
            }
        case .closing:
            board.configure(guide: nil)
            services.message.clear()
            // The closing argument is the screen most worth reading, and the
            // next press starts the choice, so it waits a little longer.
            closeGate(for: 1.8)
        case .free:
            phase = .working
            board.configure(guide: nil)
            services.message.clear()
        }
        refreshScanning()
        announceStep()
    }

    private func advance() {
        switch step {
        case .problem: enter(.oneSwitch)
        case .oneSwitch: enter(.aphasia)
        case .aphasia: enter(.ukrainian)
        case .ukrainian: enter(.closing)
        case .closing, .free: enter(.free)
        }
    }

    private func continueFlow() {
        guard gateIsOpen else { return }
        services.feedback.select()
        advance()
    }

    // MARK: Step 1

    private func pressOnProblem() {
        guard gateIsOpen else { return }
        if problemRevealed {
            services.feedback.select()
            advance()
            return
        }
        // Nothing the person does reaches anyone yet. The dull knock is the
        // point of this screen: a press that goes nowhere.
        services.feedback.unavailable()
        let last = Copy.nurseLines.count - 1
        guard nurseLine < last else { return }
        nurseLine += 1
        announce(Copy.nurseLine(nurseLine)(language), in: language)
        if nurseLine == last {
            revealWithin(1.6)
        } else if nurseLine == 1 {
            // Counted from the first press, not from the screen opening:
            // someone who stops to read first still feels a press go nowhere
            // before Holos is named.
            revealWithin(12)
        }
    }

    /// Brings Holos's reveal forward to `seconds` from now — never later
    /// than it is already due.
    private func revealWithin(_ seconds: Double) {
        let due = Date.now.addingTimeInterval(seconds)
        guard due < revealDue else { return }
        revealDue = due
        revealTask?.cancel()
        revealTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self else { return }
            self.reveal()
        }
    }

    private func reveal() {
        guard step == .problem, !problemRevealed else { return }
        problemRevealed = true
        closeGate(for: 1.0)
        services.feedback.enter()
        let words = Bilingual.joined([Copy.problemReveal, Copy.pressToStart])
        announce(words(language), in: language)
    }

    // MARK: Steps 2 and 3

    private func beginWorking() {
        guard step.isGuided, phase == .intro else { return }
        services.feedback.select()
        phase = .working
        pressBaseline = services.hub.pressCount
        lastTarget = board.guideTarget
        scheduleStuck()
        refreshScanning()
        if let target = board.guideTarget {
            announce(Copy.nextHint(target)(language, services.settings.gender), in: language)
        }
    }

    private func boardChanged() {
        guard step.isGuided, phase == .working else { return }
        let target = board.guideTarget
        guard target != lastTarget else { return }
        // Real progress, so the "are you stuck?" clock starts again.
        lastTarget = target
        scheduleStuck()
        if let target {
            announce(Copy.nextHint(target)(language, services.settings.gender), in: language)
        }
    }

    /// Any spoken message finishes a guided step, not only the goal: the
    /// person said something, which is the whole point.
    private func spoken(_ phrases: [Phrase]) {
        guard step.isGuided, phase == .working else { return }
        if absorbedQuickPhrase(phrases) { return }
        stuckTask?.cancel()
        phase = .done
        finalPresses = max(0, services.hub.pressCount - pressBaseline)
        let said = phrases.isEmpty ? (board.guide?.phrases ?? []) : phrases
        spokenPhrases = said
        spokenWords = Bilingual.joined(said.map(\.speech))
        if step == .oneSwitch, !said.isEmpty {
            firstMessage = said
        }
        // Long enough to hear your own sentence before a press moves on.
        closeGate(for: 1.6)
        refreshScanning()
        // After the voice, not over it: the person's words come first.
        announceLater(successTitle, after: 2.5)
    }

    /// Step 2's goal begins "I’m in pain", and the quick row — scanned two
    /// rows before the Pain & body cells — has a cell that says exactly
    /// that. Choosing it is a fair way to say the first half, not the end of
    /// the step: it speaks as usual, the same words go into the message, and
    /// the Next tag moves on to Medicine.
    private func absorbedQuickPhrase(_ phrases: [Phrase]) -> Bool {
        guard step == .oneSwitch, phrases.count == 1, let said = phrases.first,
              Vocabulary.quick.contains(where: { $0.id == said.id }),
              let stop = board.guide?.nextStop(after: services.message.phrases),
              stop.phrase.speech == said.speech
        else { return false }
        return services.message.add(stop.phrase)
    }

    /// True when what was said holds the whole goal, in order.
    var saidTheGoal: Bool {
        guard let guide = board.guide, !spokenPhrases.isEmpty else { return false }
        return guide.nextStop(after: spokenPhrases) == nil
    }

    /// The success card's headline: never more credit than was earned.
    var successTitle: Bilingual {
        if usedShowMe { return Copy.successShown }
        if step == .aphasia, saidTheGoal { return Copy.successTwoTitle }
        return Copy.successOneTitle
    }

    private func showMe() {
        guard step.isGuided, phase == .working, let guide = board.guide else { return }
        usedShowMe = true
        // Finish first, so the scan is already stopped when the board changes.
        spoken(guide.phrases)
        services.message.clear()
        for phrase in guide.phrases {
            services.message.add(phrase)
        }
        board.configure(guide: guide, topic: guide.stops.last?.topic)
        services.feedback.speak()
        services.speaker.say(services.message.words)
    }

    private func scheduleStuck() {
        stuckTask?.cancel()
        stuckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Experience.stuckSeconds))
            guard !Task.isCancelled, let self else { return }
            self.offerShowMe()
        }
    }

    private func offerShowMe() {
        guard step.isGuided, phase == .working, !board.offersShowMe else { return }
        board.offerShowMe()
        // A gentle "something new" cue; the button appears lit at the top.
        services.feedback.enter()
        let words = Bilingual.joined([Copy.stuckNote, Copy.showMe], separator: " ")
        announce(words(language), in: language)
    }

    // MARK: Closing

    /// Bound again right before the closing scan is loaded. Core's Speaker
    /// has one "message finished" hook and the scanner bound last owns it,
    /// so whichever scan is about to go live must be the last one bound —
    /// or someone using auditory prompts stops hearing the lit item.
    private func bindChoices() {
        choices.bind(
            to: services,
            label: { id in
                switch id {
                case Experience.keepTalkingID: Copy.keepTalking
                case Experience.startAgainID: Copy.startAgain
                default: nil
                }
            },
            onSelect: { [weak self] id in self?.choose(id) }
        )
    }

    private func choose(_ id: String) {
        switch id {
        case Self.keepTalkingID: keepTalking()
        case Self.startAgainID: restart()
        default: break
        }
    }

    // MARK: - Scanning and timing

    /// Starts or stops each scanner to match the step and the access mode.
    private func refreshScanning() {
        let boardLive = modeIsScanning && (step == .free || (step.isGuided && phase == .working))
        if boardLive {
            board.startScanning()
        } else {
            board.stopScanning()
        }
        if modeIsScanning, step == .closing {
            if choices.state == .stopped {
                // Loaded but not lit: the first press after reading starts
                // it. "Keep talking" comes first, because the board is the
                // real app and the natural thing after the tour is to use it.
                bindChoices()
                choices.load([.item(Self.keepTalkingID), .item(Self.startAgainID)], start: false)
            }
        } else if choices.state != .stopped {
            choices.stop()
        }
    }

    private var gateIsOpen: Bool { Date.now >= gateOpensAt }

    private func closeGate(for seconds: Double) {
        gateOpensAt = Date.now.addingTimeInterval(seconds)
    }

    private func announceStep() {
        let words: Bilingual
        switch step {
        case .problem: words = Bilingual.joined([Copy.problemPersona, Copy.problemBody])
        case .oneSwitch:
            let goal = Bilingual.joined([Copy.goalSay, Vocabulary.goalOne.sentence], separator: ": ")
            words = Bilingual.joined([Copy.oneSwitchTitle, goal], separator: ". ")
        case .aphasia: words = Bilingual.joined([Copy.aphasiaTitle, Copy.aphasiaStory], separator: ". ")
        case .ukrainian: words = Copy.ukrainianTitle
        case .closing: words = Copy.closingTitle
        case .free: words = Bilingual.joined([Copy.freeTitle, Copy.freeBody], separator: ". ")
        }
        announce(words(language, services.settings.gender), in: language)
    }

    private func announceLater(_ words: Bilingual, after seconds: Double) {
        announceTask?.cancel()
        announceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self else { return }
            announce(words(self.language), in: self.language)
        }
    }

    // MARK: - Previews

    /// Jumps straight to a step for a SwiftUI preview.
    func showForPreview(_ next: FlowStep, phase previewPhase: FlowPhase = .working) {
        hasStarted = true
        enter(next)
        switch previewPhase {
        case .intro:
            break
        case .working:
            if next.isGuided { beginWorking() }
        case .done, .headTry:
            if next.isGuided {
                phase = .working
                spoken(board.guide?.phrases ?? [])
                if previewPhase == .headTry, next == .aphasia {
                    phase = .headTry
                }
            }
        }
    }
}
