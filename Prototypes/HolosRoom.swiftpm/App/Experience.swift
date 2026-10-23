import Foundation
import Observation

/// The judged story, one stage at a time — and the free room after it.
///
/// One object owns every decision about where a switch press goes, because
/// a one-switch app has exactly one way to get stuck: a press that lands
/// nowhere. Each stage says what a press means (continue, scan the room,
/// scan a card's two buttons) in `refresh()`, and nothing else routes.
@MainActor
@Observable
final class Experience {
    private(set) var stage: Stage = .problemAsk
    /// Turns true a moment after a narrative or button card appears, so one
    /// bounce of a switch can never skip two cards.
    private(set) var canContinue = false
    private(set) var isScanning = true
    private(set) var helpOffered = false
    private(set) var doneTargets: Set<String> = []
    /// Whether the last guided step was finished with its goal (or with the
    /// person's own message — also fine, never a failure).
    private(set) var lastGoalMet = true
    /// The nurse speaks in text only: the voice belongs to the person.
    private(set) var nurseLine: Bilingual?
    private(set) var showsSilence = false
    private(set) var saidInUkrainian = false
    /// The message built in step 2, replayed in Ukrainian in step 4.
    private(set) var firstMessage: [Phrase] = []
    /// The judge's own language while step 4 has switched the board to
    /// Ukrainian. Observed, because the Ukrainian card keeps explaining
    /// itself in this language (see `readingLanguage`).
    private(set) var languageBeforeUkrainian: Language?

    let services: HolosServices
    let board = RoomBoardModel()
    /// Walks the two big buttons on the Ukrainian and closing cards.
    let cardScanner = Scanner()

    @ObservationIgnored private var choicesInStep = 0
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var readTimer: Task<Void, Never>?
    @ObservationIgnored private var stuckTimer: Task<Void, Never>?

    /// Long enough that a double bounce is ignored, short enough that
    /// nobody notices waiting.
    static let minimumReadSeconds = 1.2
    /// Forty-five seconds without progress, and help is offered.
    static let stuckSeconds = 45.0

    init(services: HolosServices) {
        self.services = services
        // A card with two big buttons has nothing to rest from, and a scan
        // that pauses unseen while the judge reads the closing words would
        // turn "Keep talking" into two presses. (Scanners are bound in
        // `refresh()`, just before each one is used.)
        cardScanner.loopsBeforePause = 1000
    }

    // MARK: - Lifecycle

    /// Called by the root view when it appears. Safe to call again.
    func start(isScanning: Bool) {
        self.isScanning = isScanning
        if hasStarted {
            refresh()
        } else {
            hasStarted = true
            go(to: .problemAsk)
        }
    }

    /// Scanning or touch changed — in Settings, or because VoiceOver or
    /// Switch Control came on. Both scanners restart cleanly in the new mode.
    func setScanning(_ value: Bool) {
        guard value != isScanning else { return }
        isScanning = value
        board.touchPath = []
        board.scanner.stop()
        cardScanner.stop()
        refresh()
    }

    func go(to next: Stage) {
        readTimer?.cancel()
        stuckTimer?.cancel()
        board.scanner.stop()
        cardScanner.stop()
        stage = next
        doneTargets = []
        choicesInStep = 0
        helpOffered = false
        canContinue = false

        switch next {
        case .problemAsk:
            board.reset(to: .ward)
            nurseLine = Copy.nurseAsks
            showsSilence = false
            saidInUkrainian = false
            firstMessage = []
            services.message.clear()
        case .problemSilent:
            showsSilence = true
        case .scanRoom:
            board.reset(to: .ward)
            nurseLine = Copy.nurseAsks
            showsSilence = false
            services.message.clear()
        case .scanDone:
            // She answers what was actually asked for.
            let askedForMedicine = services.message.phrases.contains { $0.id == "ward.table.medicine" }
            nurseLine = askedForMedicine ? Copy.nurseMedicine : Copy.nurseUnderstood
        case .familiarIntro:
            nurseLine = nil
        case .familiar:
            board.reset(to: .home)
            services.message.clear()
        case .familiarDone, .headTry, .closing:
            break
        case .ukrainian:
            board.reset(to: .ward)
            nurseLine = nil
            saidInUkrainian = false
            services.message.clear()
            for phrase in ukrainianMessage {
                services.message.add(phrase)
            }
        case .free:
            board.touchPath = []
        }

        // Narrative cards and the two button cards both wait a moment before
        // a press counts, so one bounce of a switch can never skip a card.
        if isNarrative || !cardItems.isEmpty { startReadTimer() }
        if boardMode == .guided { startStuckTimer() }
        refresh()
        let language = services.settings.language
        let spoken = announcement
        if !spoken.isEmpty {
            announce(spoken, in: language)
        }
    }

    /// Points every switch press at whatever the current stage needs.
    func refresh() {
        let hub = services.hub
        switch stage {
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone:
            hub.route { [weak self] _ in
                self?.continuePressed()
            }
        case .scanRoom, .familiar, .free:
            if isScanning {
                // Bound before loading, so the first lit item is announced;
                // and bound again here because the speaker has one "message
                // finished" hook, and the last scanner bound owns it.
                bindBoard()
                if board.scanner.state == .stopped {
                    board.scanner.load(board.tree(includeHelp: helpOffered))
                }
                board.scanner.listen(to: hub)
            } else {
                board.scanner.stop()
                hub.unroute()
            }
        case .headTry:
            // HeadTryPanel routes presses itself while it is on screen, and
            // hands back through `headTryDone()`.
            break
        case .ukrainian, .closing:
            if !isScanning {
                cardScanner.stop()
                hub.unroute()
            } else if stage == .ukrainian, !saidInUkrainian {
                // Until the Ukrainian has been heard, the card has one thing
                // to do, so any press does it: a mistimed press can never
                // skip the part the whole app exists for.
                cardScanner.stop()
                hub.route { [weak self] _ in
                    self?.sayPressed()
                }
            } else {
                bindCard()
                if cardScanner.state == .stopped {
                    cardScanner.load(cardItems)
                }
                hub.route { [weak self] _ in
                    // An early press is ignored outright, rather than given
                    // the feel of a choice that did not happen.
                    guard let self, self.canContinue else { return }
                    self.cardScanner.press()
                }
            }
        }
    }

    // MARK: - Narrative presses

    func continuePressed() {
        guard isNarrative, canContinue else { return }
        switch stage {
        case .problemAsk:
            // The one button, with nothing to choose: a dull knock and an
            // empty bubble. That silence is the problem.
            services.feedback.unavailable()
            go(to: .problemSilent)
        case .problemSilent:
            services.feedback.enter()
            go(to: .scanRoom)
        case .scanDone:
            services.feedback.enter()
            go(to: .familiarIntro)
        case .familiarIntro:
            services.feedback.enter()
            go(to: .familiar)
        case .familiarDone:
            services.feedback.enter()
            go(to: .headTry)
        case .scanRoom, .familiar, .headTry, .ukrainian, .closing, .free:
            break
        }
    }

    /// HeadTryPanel's `onDone`: it has already let go of the switch.
    func headTryDone() {
        go(to: .ukrainian)
    }

    // MARK: - Board choices

    /// A finger on a cell, chip or control: the same action a scan would
    /// take, plus the feel the scanner would have given it.
    func touched(_ id: String) {
        guard boardMode != .inert else { return }
        switch id {
        case MessageBar.speakID:
            break // speakMessage gives its own feel, or a knock if empty.
        case MessageBar.deleteID:
            if !services.message.isEmpty { services.feedback.back() }
        case MessageBar.clearID, MessageBar.clearConfirmID:
            if services.message.isEmpty {
                services.feedback.unavailable()
            } else {
                services.feedback.back()
            }
        default:
            services.feedback.select()
        }
        perform(id)
    }

    func touchHotspot(_ id: String) {
        guard boardMode != .inert, let spot = Vocabulary.hotspot(id) else { return }
        services.feedback.enter()
        board.touchPath = [id]
        let language = services.settings.language
        announce(spot.name(language), in: language)
    }

    func touchRing(_ item: RingItem) {
        guard boardMode != .inert else { return }
        guard let choice = item.choice else {
            services.feedback.back()
            if !board.touchPath.isEmpty { board.touchPath.removeLast() }
            return
        }
        if choice.opensMore {
            services.feedback.enter()
            board.touchPath = Array(board.touchPath.prefix(1)) + [choice.id]
        } else {
            services.feedback.select()
            perform(choice.id)
        }
    }

    private func perform(_ id: String) {
        switch id {
        case RoomIDs.sceneChip:
            switchPlace()
        case RoomIDs.languageChip:
            switchLanguage()
        case RoomIDs.helpChip:
            showMe()
        case MessageBar.speakID:
            let words = services.message.words
            let hadWords = !services.message.isEmpty
            MessageBar.speakMessage(services: services)
            if hadWords {
                board.showSpoken(words)
                noteChoice(nil, wholeMessage: true)
            }
        default:
            if MessageBar.perform(id, services: services) { return }
            if let phrase = Vocabulary.phrase(id) { say(phrase) }
        }
    }

    /// Every choice speaks at once — no Speak press needed — and joins the
    /// message strip, so two choices make a two-part message Speak can replay.
    private func say(_ phrase: Phrase) {
        services.speaker.say(phrase.speech)
        services.message.add(phrase)
        board.showSpoken(phrase.speech)
        noteChoice(phrase.id, wholeMessage: false)
    }

    /// Moves a guided step on when its goal is met — or when the person has
    /// said something of their own of the same length. A different sentence
    /// is still a sentence; it is never treated as a mistake.
    private func noteChoice(_ id: String?, wholeMessage: Bool) {
        guard boardMode == .guided else { return }
        if let id {
            choicesInStep += 1
            if targets.contains(id), !doneTargets.contains(id) {
                doneTargets.insert(id)
                startStuckTimer()
            }
        }
        let goalMet = doneTargets.count >= targets.count
        let ownMessage = wholeMessage || choicesInStep >= targets.count
        guard goalMet || ownMessage else { return }
        lastGoalMet = goalMet
        switch stage {
        case .scanRoom:
            firstMessage = services.message.phrases
            go(to: .scanDone)
        case .familiar:
            go(to: .familiarDone)
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone, .headTry, .ukrainian, .closing, .free:
            break
        }
    }

    /// Changes the room, and the scan with it: a scan left walking the other
    /// room's objects would light nothing on screen.
    ///
    /// Loading from inside a selection is safe: the scanner reports the
    /// selection last, so the new tree has the final word.
    private func show(_ place: RoomPlace) {
        guard place != board.place else { return }
        board.place = place
        board.touchPath = []
        let language = services.settings.language
        announce(place.name(language), in: language)
        if isScanning, boardMode != .inert {
            board.scanner.load(board.tree(includeHelp: helpOffered))
        }
    }

    private func switchPlace() {
        show(board.place.other)
        board.clearSpoken()
    }

    private func switchLanguage() {
        let settings = services.settings
        settings.language = settings.language.other
        announce(settings.language.nativeName, in: settings.language)
    }

    /// Does the next part of the goal for someone who is stuck — the very
    /// same speech and bubble, so they see where it came from.
    private func showMe() {
        guard let id = nextTargetID, let phrase = Vocabulary.phrase(id) else { return }
        // The room first, so the bubble appears in the room the words belong
        // to — and if this finishes the goal, the step ends the new scan.
        if let route = Vocabulary.route(to: id) {
            show(route.place)
        }
        say(phrase)
    }

    // MARK: - Card choices

    func cardTouched(_ id: String) {
        services.feedback.select()
        cardSelected(id)
    }

    /// A switch press on the Ukrainian card before it has been said: the
    /// lit "Say it in Ukrainian" is the only thing a press can do.
    private func sayPressed() {
        guard stage == .ukrainian, canContinue else { return }
        services.feedback.select()
        sayInUkrainian()
    }

    private func cardSelected(_ id: String) {
        switch id {
        case RoomIDs.sayUkrainian:
            sayInUkrainian()
        case RoomIDs.cardContinue:
            finishUkrainian()
        case RoomIDs.keepTalking:
            go(to: .free)
        case RoomIDs.startAgain:
            services.speaker.stop()
            go(to: .problemAsk)
        default:
            break
        }
    }

    /// The board itself switches to Ukrainian — every pill in the room
    /// relabels behind the card — and the same message is spoken.
    private func sayInUkrainian() {
        let settings = services.settings
        if languageBeforeUkrainian == nil {
            languageBeforeUkrainian = settings.language
        }
        settings.language = .ukrainian
        services.speaker.refreshVoices()
        let words = Bilingual.joined(ukrainianMessage.map(\.speech))
        services.feedback.speak()
        services.speaker.say(words)
        board.showSpoken(words)
        saidInUkrainian = true
        // Now there is a real choice — say it again, or move on — so the
        // card's two-button scan takes over (or keeps running, if it already
        // was).
        refresh()
    }

    /// Back to the language the judge had before step 4, so the closing
    /// card is read in it.
    private func finishUkrainian() {
        if let previous = languageBeforeUkrainian {
            services.settings.language = previous
            languageBeforeUkrainian = nil
        }
        go(to: .closing)
    }

    // MARK: - Timers and wiring

    private func startReadTimer() {
        readTimer?.cancel()
        canContinue = false
        let seconds = Self.minimumReadSeconds
        readTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self else { return }
            self.canContinue = true
            self.promptLoneButton()
        }
    }

    /// The Ukrainian card's "Say it in Ukrainian" lights up on its own once a
    /// press will count; with auditory prompts on it is read out, like any
    /// item a scan lights.
    private func promptLoneButton() {
        guard stage == .ukrainian, !saidInUkrainian, isScanning,
              services.settings.auditoryPrompts else { return }
        services.speaker.prompt(Copy.sayInUkrainian)
    }

    private func startStuckTimer() {
        stuckTimer?.cancel()
        guard boardMode == .guided, !helpOffered else { return }
        let seconds = Self.stuckSeconds
        stuckTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.offerHelp()
        }
    }

    private func offerHelp() {
        guard boardMode == .guided, !helpOffered else { return }
        helpOffered = true
        let language = services.settings.language
        announce((isScanning ? Copy.helpOfferedScanning : Copy.helpOfferedTouch)(language), in: language)
        if isScanning {
            board.scanner.load(board.tree(includeHelp: true))
        }
    }

    /// Binding also hands this scanner the speaker's one "message finished"
    /// hook (it re-reads the lit item after every spoken choice), so each
    /// scanner is bound again whenever it takes over — after the other one,
    /// or after the head-turn panel's own scan.
    private func bindBoard() {
        board.scanner.bind(to: services, label: { [weak self] id in
            self?.label(for: id)
        }, onSelect: { [weak self] id in
            self?.perform(id)
        })
    }

    private func bindCard() {
        cardScanner.bind(to: services, label: { [weak self] id in
            self?.cardLabel(for: id)
        }, onSelect: { [weak self] id in
            self?.cardSelected(id)
        })
    }
}
