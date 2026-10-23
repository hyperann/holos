import SwiftUI

/// Steps 2 and 3, and free conversation afterwards: the conversation beside
/// the answers — or, after "Something else" or when nobody is asking, the
/// whole board.
///
/// It owns the answers' scanner and decides which scan runs. Whatever the
/// story changes — a new question, the whole board opening, the nurse
/// taking her turn — shows up as a new `scanTree` or a change of
/// `wholeBoardIsLive`, and the right scan restarts on it, a moment after
/// the new screen appears.
struct ConversationScreen: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var scanner = Scanner()
    @State private var settle: Task<Void, Never>?
    @State private var boardSettle: Task<Void, Never>?

    /// A new set of answers appears a moment before anything lights up, so
    /// the eye can land on the question first instead of chasing the scan.
    /// The whole board waits the same moment.
    private static let settleSeconds: Double = 0.8

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    /// The screen is the switch unless the head-turn panel is up, which
    /// brings its own.
    private var screenIsSwitch: Bool {
        isScanning && !experience.isShowingHeadTry
    }

    private var boardIsLive: Bool {
        isScanning && experience.wholeBoardIsLive
    }

    /// On a phone the answers get most of the height: six cells and a strip
    /// must stay big enough to hit, while the chat scrolls itself to the
    /// newest line and the question is repeated above the answers anyway.
    private var chatShare: CGFloat {
        sizeClass == .compact ? 0.2 : 0.34
    }

    var body: some View {
        let showsBoard = experience.conversation.showsWholeBoard
        VStack(spacing: 14) {
            topBar
            VoiceNotice()
            // The head-turn panel covers only what lies under the top bar,
            // so Settings and the language toggle stay in reach.
            ZStack {
                if showsBoard {
                    WholeBoardScreen(isScanning: isScanning, isSwitch: screenIsSwitch)
                        .transition(.opacity)
                } else {
                    SplitLayout(chatShare: chatShare) {
                        // A clean tap presses; a drag scrolls back through
                        // what was said.
                        ChatView()
                            .pressOnTap(isActive: screenIsSwitch)
                    } board: {
                        // The answers are Core's touch-down switch: a shaking
                        // hand never loses a press here.
                        AnswerArea(scanner: scanner, isScanning: isScanning)
                            .switchTapArea(isActive: screenIsSwitch)
                    }
                    .transition(.opacity)
                }
                if experience.isShowingHeadTry {
                    headTryOverlay
                        .transition(.opacity)
                }
            }
        }
        .padding(16)
        // Fades only, so nothing to change for Reduce Motion.
        .animation(.easeInOut(duration: 0.3), value: experience.isShowingHeadTry)
        .animation(.easeInOut(duration: 0.25), value: showsBoard)
        .onAppear { configure() }
        .onDisappear {
            settle?.cancel()
            boardSettle?.cancel()
            scanner.stop()
            experience.board.stopScanning()
        }
        .onChange(of: experience.scanTree) { reload() }
        .onChange(of: boardIsLive) { reloadBoard() }
        .onChange(of: isScanning) {
            reload()
            reloadBoard()
        }
        .onChange(of: experience.step) { announceStep() }
    }

    // MARK: - Pieces

    /// Outside the switch area, so a carer can always tap it. The language
    /// toggle in it is ALSO the last stop of the answers' scan, so a switch
    /// user can reach Ukrainian without anyone's help; the whole board has
    /// its own language cell.
    private var topBar: some View {
        TopBar(languageLit: scanner.isHighlighted(BoardID.language)) {
            if experience.step == .free {
                AskMenu()
            } else {
                GoalBanner(
                    isScanning: isScanning,
                    showMeLit: scanner.isHighlighted(BoardID.showMe)
                        || experience.board.scanner.isHighlighted(GridIDs.showMe)
                )
            }
        }
    }

    private var headTryOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .switchTapArea(isActive: isScanning)
                .accessibilityHidden(true)
            // Core's panel pauses the answers' scanner while it is shown and
            // routes presses back to it before `onDone`, so not a single
            // press falls between the two. The whole board is never open
            // under it: the answer that ends step 3 closes the board.
            HeadTryPanel(pausing: scanner) {
                experience.headTryDone()
            }
            // VoiceOver and Switch Control stay inside the panel while it is
            // up, as they would in an alert.
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .padding(12)
        }
    }

    // MARK: - Scanning

    private func configure() {
        claimSwitch()
        reload()
        reloadBoard()
        announceStep()
    }

    /// Every press goes to whichever board is showing. The handler keeps its
    /// own references, so it never depends on this view value still being
    /// on screen.
    private func claimSwitch() {
        let story = experience
        let answers = scanner
        hub.route { [weak story, weak answers] _ in
            guard let story else { return }
            if story.conversation.showsWholeBoard {
                story.board.scanner.press()
            } else {
                answers?.press()
            }
        }
    }

    /// Core's Speaker has one "message finished" hook, and the scanner bound
    /// last owns it. The whole board binds its own scanner, so the answers
    /// bind again every time they come back.
    private func bindAnswers() {
        let story = experience
        let answers = scanner
        scanner.bind(to: services, label: { id in
            BoardID.label(for: id)
        }, onSelect: { [weak story, weak answers] id in
            // "Something else" hands the switch to the whole board. Stopped
            // here, not when the screen next draws, so Core does not read
            // out the answers' first item as the board appears.
            if id == Vocabulary.somethingElse.id {
                answers?.stop()
            }
            story?.activate(id)
        })
    }

    private func reload() {
        settle?.cancel()
        let tree = experience.scanTree
        guard isScanning, !tree.isEmpty else {
            scanner.load(tree, start: false)
            return
        }
        // Bound while stopped, so binding announces nothing by itself.
        scanner.load(tree, start: false)
        bindAnswers()
        let answers = scanner
        settle = Task {
            try? await Task.sleep(for: .seconds(ConversationScreen.settleSeconds))
            guard !Task.isCancelled else { return }
            answers.load(tree)
        }
    }

    /// Starts the whole board's scan a moment after the board appears, and
    /// stops it as soon as the board is not the thing being used.
    private func reloadBoard() {
        boardSettle?.cancel()
        let board = experience.board
        guard boardIsLive else {
            board.stopScanning()
            return
        }
        guard board.scanner.state == .stopped else { return }
        boardSettle = Task {
            try? await Task.sleep(for: .seconds(ConversationScreen.settleSeconds))
            guard !Task.isCancelled else { return }
            board.startScanning()
        }
    }

    /// Only free conversation is announced here. In the guided story each
    /// turn announces itself — step, question and goal together — once the
    /// nurse has asked (`Experience.runTurn`), so the two never talk over
    /// each other.
    private func announceStep() {
        guard experience.step == .free else { return }
        let language = settings.language
        announce(Copy.freeNote(language), in: language)
    }
}

#Preview("Conversation") {
    let experience = Experience.preview(.conversation)
    return ConversationScreen()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}

#Preview("Step 3 — the whole board") {
    let experience = Experience.preview(.conversation, boardOpen: true)
    return ConversationScreen()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}

#Preview("Free — the board is home") {
    let experience = Experience.preview(.free)
    return ConversationScreen()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
