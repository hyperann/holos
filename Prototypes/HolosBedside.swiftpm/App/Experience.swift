import Foundation
import Observation

/// Runs the three-minute story and owns the conversation.
///
/// Screens stay simple: they draw what is here and report presses back.
/// Every timed beat — the nurse typing, waiting for the person's words to
/// finish before she answers, the 45-second "Show me" offer — lives in
/// this one place, as cancellable tasks, so leaving a step can never leave
/// a stray timer behind to fire into the next one.
@MainActor
@Observable
final class Experience {
    enum Step: Equatable, Sendable {
        /// Step 1: the nurse asks and there is no way to answer.
        case problem
        /// Steps 2 and 3: the guided conversation, then the optional
        /// head-turn panel.
        case conversation
        /// Step 4: the transcript again, spoken in Ukrainian.
        case ukrainian
        /// Who it is for, and why it is free and open.
        case closing
        /// The real app: free conversation, with the partner's question
        /// cards.
        case free
    }

    let services: HolosServices
    let conversation: Conversation

    private(set) var step: Step = .problem

    // Step 1
    /// Presses made while there was nothing to press for.
    private(set) var deadPresses = 0
    private(set) var problemCardShown = false
    /// True once the card has been up long enough to read, so a double
    /// press cannot skip it unseen.
    private(set) var problemCardReady = false

    // Steps 2 and 3
    private(set) var turnIndex = 0
    private(set) var showMeOffered = false
    private(set) var isShowingHeadTry = false

    // Step 4
    private(set) var replayingLineID: Int?
    private(set) var replayReady = false
    private(set) var replayFinished = false

    /// What the person said last, so the nurse's next question can fit it.
    @ObservationIgnored private var lastAnswerID: String?
    @ObservationIgnored private var pending: Task<Void, Never>?
    @ObservationIgnored private var showMeTimer: Task<Void, Never>?

    /// Long enough that nobody who is trying feels hurried; short enough
    /// that nobody who is lost stays lost.
    static let showMeDelay: Double = 45
    /// The shortest time any narrative card stays up before a press counts.
    static let minimumReadTime: Double = 1.5

    init(services: HolosServices) {
        self.services = services
        conversation = Conversation()
    }

    // MARK: - Choosing

    /// Runs whatever the person chose, by scan or by touch.
    func activate(_ id: String) {
        if id == BoardID.language {
            toggleLanguage()
        } else if id == BoardID.showMe {
            showMe()
        } else if id == BoardID.miniClose {
            closeMiniBoard()
        } else if id == Vocabulary.somethingElse.id {
            openMiniBoard()
        } else if let topic = MiniTopic(scanID: id) {
            showTopic(topic)
        } else if let phrase = Vocabulary.phrase(id: id) {
            personAnswered(phrase)
        }
    }

    func toggleLanguage() {
        let settings = services.settings
        settings.language = settings.language.other
        announce(settings.language.nativeName, in: settings.language)
    }

    private func openMiniBoard() {
        if step == .conversation, conversation.isPartnerTurn { return }
        conversation.openMiniBoard()
        // A VoiceOver user hears which board this is and how it works; the
        // cells carry the guide as their value.
        let language = services.settings.language
        announce("\(conversation.miniTopic.title(language)). \(Copy.miniHelp(language))", in: language)
        // Opening the board is progress; the "Show me" clock starts again.
        if step == .conversation { armShowMe() }
    }

    private func showTopic(_ topic: MiniTopic) {
        conversation.showTopic(topic)
        let language = services.settings.language
        announce(topic.title(language), in: language)
        // Choosing a topic is progress too.
        if step == .conversation { armShowMe() }
    }

    /// Back to the answers. The question is said again, because everything
    /// under a VoiceOver user's finger has just changed.
    private func closeMiniBoard() {
        conversation.closeMiniBoard()
        let language = services.settings.language
        let question = conversation.prompt ?? conversation.question.prompt
        announce("\(Copy.questionLabel(language)): \(question(language))", in: language)
    }

    /// Chooses the turn's answer on the person's behalf — the way out for
    /// anyone who is stuck, so no one can be trapped in a guided step.
    func showMe() {
        guard let turn = currentTurn, !conversation.isPartnerTurn,
              let phrase = Vocabulary.phrase(id: turn.target)
        else { return }
        personAnswered(phrase)
    }

    /// The person's words go into the conversation and are spoken aloud.
    /// In the guided story, the nurse answers once they have finished.
    func personAnswered(_ phrase: Phrase) {
        if step == .conversation, conversation.isPartnerTurn { return }
        conversation.closeMiniBoard()
        conversation.addPerson(phrase)
        services.feedback.speak()
        services.speaker.say(phrase.speech)

        guard step == .conversation, NurseScript.turns.indices.contains(turnIndex) else { return }
        let turn = NurseScript.turns[turnIndex]
        let hitTarget = phrase.id == turn.target
        lastAnswerID = phrase.id
        cancelShowMe()
        conversation.isPartnerTurn = true
        let reply = hitTarget ? turn.replyToTarget : turn.replyToOther
        let index = turnIndex
        pending?.cancel()
        pending = Task { [weak self] in
            await self?.respond(with: reply, afterTurn: index)
        }
    }

    // MARK: - Step 1: the problem

    /// The scene where nothing can be said. Driven by the step's `.task`,
    /// so it stops by itself if the step goes away.
    func runProblemScene() async {
        conversation.reset()
        deadPresses = 0
        problemCardShown = false
        problemCardReady = false
        guard await pause(0.8) else { return }
        guard await nurseSays(Copy.nurseGreeting) else { return }
        guard await pause(4.0) else { return }
        guard await nurseSays(Copy.nurseWaiting) else { return }
        guard await pause(3.5) else { return }
        guard await nurseSays(Copy.nurseTakeTime) else { return }
        guard await pause(4.0) else { return }
        guard await nurseSays(Copy.nurseLater) else { return }
        guard await pause(1.2) else { return }
        conversation.append(.note, Copy.noteNurseLeft)
        guard await pause(1.6) else { return }
        problemCardShown = true
        let language = services.settings.language
        announce(Copy.cardTitle(language), in: language)
        guard await pause(Self.minimumReadTime) else { return }
        problemCardReady = true
    }

    /// Every press in step 1. Before the card, a press finds nothing —
    /// a dull knock, and the screen says so. That is the point.
    func problemPressed() {
        guard step == .problem else { return }
        if problemCardReady {
            beginConversation()
        } else if !problemCardShown {
            deadPresses += 1
            services.feedback.unavailable()
        } else {
            // The card has only just appeared: "not yet", never silence.
            services.feedback.unavailable()
        }
    }

    private func beginConversation() {
        // The press that moves the story on is felt and heard like a choice.
        services.feedback.select()
        problemCardShown = false
        problemCardReady = false
        step = .conversation
        lastAnswerID = nil
        turnIndex = 0
        conversation.isPartnerTurn = true
        pending?.cancel()
        pending = Task { [weak self] in
            await self?.runTurn(0)
        }
    }

    // MARK: - Steps 2 and 3: the guided conversation

    private func runTurn(_ index: Int) async {
        guard NurseScript.turns.indices.contains(index) else { return }
        let turn = NurseScript.turns[index]
        let previous = index > 0 ? NurseScript.turns[index - 1] : nil
        turnIndex = index
        conversation.isPartnerTurn = true
        if let note = turn.note {
            guard await pause(0.6) else { return }
            conversation.append(.note, note)
        }
        // The plain question only when it fits what was actually said.
        let plainAfter: Set<String> = turn.plainAfter ?? previous.map { Set([$0.target]) } ?? []
        let fitsPlain = previous == nil || (lastAnswerID.map { plainAfter.contains($0) } ?? true)
        let asks = fitsPlain ? turn.asks : (turn.asksIfSurprised ?? turn.asks)
        // Not announced on its own: it goes out with the goal just below, as
        // two announcements posted back to back cut each other off.
        guard await nurseSays(asks, announces: false) else { return }
        conversation.setQuestion(turn.question, prompt: asks)
        conversation.isPartnerTurn = false
        announceTurn(turn, asks: asks, withStep: previous?.stage != turn.stage)
        armShowMe()
    }

    /// One announcement per turn, in one language: where the story is (when
    /// the step has just changed), what the nurse asked, and what to do.
    private func announceTurn(_ turn: NurseTurn, asks: Bilingual, withStep: Bool) {
        let language = services.settings.language
        var parts: [String] = []
        if withStep {
            parts.append(turn.stepLabel(language) + ".")
        }
        parts.append("\(Copy.roleNurse(language)): \(asks(language))")
        parts.append(turn.goal(language))
        announce(parts.joined(separator: " "), in: language)
    }

    private func respond(with reply: [Bilingual], afterTurn index: Int) async {
        // Never talk over the person: the nurse waits for their sentence.
        guard await waitForSpeech() else { return }
        for line in reply {
            guard await nurseSays(line) else { return }
            guard await pause(0.5) else { return }
        }
        if NurseScript.turns.indices.contains(index + 1) {
            await runTurn(index + 1)
        } else {
            guard await pause(1.0) else { return }
            isShowingHeadTry = true
        }
    }

    /// The optional head-turn moment is over, by Skip or by success.
    func headTryDone() {
        isShowingHeadTry = false
        startReplay()
    }

    private func armShowMe() {
        cancelShowMe()
        showMeTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Experience.showMeDelay))
            guard !Task.isCancelled else { return }
            self?.showMeOffered = true
        }
    }

    private func cancelShowMe() {
        showMeTimer?.cancel()
        showMeTimer = nil
        showMeOffered = false
    }

    // MARK: - Step 4: hear it in Ukrainian

    private func startReplay() {
        pending?.cancel()
        cancelShowMe()
        // The judge's own language is left alone. Only the transcript is
        // drawn in Ukrainian (`ReplayStep`), which every line can do because
        // it kept its meaning in both languages — so the explanation around
        // it stays readable, and nothing half-finished is saved to disk.
        replayingLineID = nil
        replayReady = false
        replayFinished = false
        step = .ukrainian
        pending = Task { [weak self] in
            await self?.runReplay()
        }
    }

    private func runReplay() async {
        guard await pause(Self.minimumReadTime) else { return }
        replayReady = true
        let speaker = services.speaker
        let gender = services.settings.gender
        for line in conversation.personLines {
            replayingLineID = line.id
            services.feedback.speak()
            if speaker.hasUkrainianVoice {
                speaker.say(line.words(.ukrainian, gender), in: .ukrainian)
            } else {
                // `say(_:in:)` stays silent without the voice, so ask for the
                // usual English fallback; the screen still shows Ukrainian.
                speaker.say(line.words)
            }
            guard await waitForSpeech() else { return }
            guard await pause(0.4) else { return }
        }
        replayingLineID = nil
        replayFinished = true
        let language = services.settings.language
        let done = speaker.hasUkrainianVoice ? Copy.replayDone : Copy.replayDoneShownOnly
        announce(done(language), in: language)
    }

    func replayPressed() {
        guard step == .ukrainian else { return }
        guard replayReady else {
            // Pressed before the screen could be read: "not yet", not silence.
            services.feedback.unavailable()
            return
        }
        services.feedback.select()
        pending?.cancel()
        services.speaker.stop()
        replayingLineID = nil
        step = .closing
    }

    // MARK: - After the story

    /// Free conversation: the board as the real app would be used.
    func keepTalking() {
        cancelAll()
        conversation.isPartnerTurn = false
        conversation.isTyping = false
        conversation.append(.note, Copy.freeNote)
        conversation.setQuestion(.feeling, prompt: nil)
        step = .free
    }

    /// A partner taps a question card. The board changes to fit it.
    func partnerAsks(_ question: Question) {
        guard step == .free else { return }
        conversation.append(.partner, question.prompt)
        conversation.setQuestion(question, prompt: question.prompt)
        let language = services.settings.language
        announce(question.prompt(language), in: language)
    }

    func newConversation() {
        services.speaker.stop()
        conversation.reset()
        conversation.append(.note, Copy.freeNote)
    }

    func restart() {
        cancelAll()
        services.speaker.stop()
        conversation.reset()
        turnIndex = 0
        lastAnswerID = nil
        isShowingHeadTry = false
        replayingLineID = nil
        replayReady = false
        replayFinished = false
        deadPresses = 0
        problemCardShown = false
        problemCardReady = false
        step = .problem
    }

    private func cancelAll() {
        pending?.cancel()
        pending = nil
        cancelShowMe()
    }

    // MARK: - Timing helpers

    /// Shows the typing dots for a moment, then the nurse's words. Her lines
    /// are text on screen, never synthesised speech: the voice in Holos
    /// belongs only to the person using it.
    ///
    /// - Parameter announces: False when the caller announces the line
    ///   itself, together with what comes next.
    private func nurseSays(_ words: Bilingual, announces: Bool = true) async -> Bool {
        conversation.isTyping = true
        let finished = await pause(0.9)
        conversation.isTyping = false
        guard finished else { return false }
        conversation.append(.nurse, words)
        if announces {
            let language = services.settings.language
            let readable = words == Copy.nurseWaiting ? Copy.nurseWaitingSpoken : words
            announce(readable(language), in: language)
        }
        return true
    }

    /// False if the waiting task was cancelled.
    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(seconds))
        return !Task.isCancelled
    }

    /// Waits for the person's sentence to finish, with a ceiling so a
    /// stuck synthesizer can never stall the story.
    private func waitForSpeech() async -> Bool {
        guard await pause(0.5) else { return false }
        var waited = 0.5
        while services.speaker.isSpeaking, waited < 7 {
            guard await pause(0.2) else { return false }
            waited += 0.2
        }
        return true
    }

    // MARK: - Previews

    static func preview(_ step: Step = .conversation) -> Experience {
        let experience = Experience(services: .preview())
        let conversation = experience.conversation
        switch step {
        case .problem:
            conversation.append(.nurse, Copy.nurseGreeting)
            conversation.append(.nurse, Copy.nurseTakeTime)
        case .conversation, .ukrainian, .closing, .free:
            conversation.append(.note, Copy.noteTenMinutes)
            conversation.append(.nurse, Copy.nurseBack)
            if let pain = Vocabulary.phrase(id: "feel.pain") {
                conversation.addPerson(pain)
            }
            conversation.append(.nurse, Copy.nurseSorry)
            conversation.append(.nurse, Copy.nurseWhereHurts)
            conversation.setQuestion(.painWhere, prompt: Copy.nurseWhereHurts)
            experience.turnIndex = 1
        }
        experience.step = step
        return experience
    }
}
