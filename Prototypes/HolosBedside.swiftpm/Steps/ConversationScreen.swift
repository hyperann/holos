import SwiftUI

/// Steps 2 and 3, and the free board afterwards: the conversation beside
/// the answers.
///
/// It owns the scanner. Whatever the story changes — a new question, the
/// "Something else" board, the nurse taking her turn — shows up as a new
/// `scanTree`, and the scan restarts on it. Nothing else in the screen
/// has to know about scanning at all.
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

    /// A new set of answers appears a moment before anything lights up, so
    /// the eye can land on the question first instead of chasing the scan.
    private static let settleSeconds: Double = 0.8

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    /// The board is the switch unless the head-turn panel is up, which
    /// brings its own.
    private var boardIsSwitch: Bool {
        isScanning && !experience.isShowingHeadTry
    }

    /// On a phone the answers get most of the height: six cells and a strip
    /// must stay big enough to hit, while the chat scrolls itself to the
    /// newest line and the question is repeated above the answers anyway.
    private var chatShare: CGFloat {
        sizeClass == .compact ? 0.2 : 0.34
    }

    var body: some View {
        VStack(spacing: 14) {
            topBar
            VoiceNotice()
            // The head-turn panel covers only what lies under the top bar,
            // so Settings and the language toggle stay in reach.
            ZStack {
                SplitLayout(chatShare: chatShare) {
                    // A clean tap presses; a drag scrolls back through what
                    // was said.
                    ChatView()
                        .pressOnTap(isActive: boardIsSwitch)
                } board: {
                    // The answers are Core's touch-down switch: a shaking
                    // hand never loses a press here.
                    AnswerArea(scanner: scanner, isScanning: isScanning)
                        .switchTapArea(isActive: boardIsSwitch)
                }
                if experience.isShowingHeadTry {
                    headTryOverlay
                        .transition(.opacity)
                }
            }
        }
        .padding(16)
        .animation(.easeInOut(duration: 0.3), value: experience.isShowingHeadTry)
        .onAppear { configure() }
        .onDisappear {
            settle?.cancel()
            scanner.stop()
        }
        .onChange(of: experience.scanTree) { reload() }
        .onChange(of: isScanning) { reload() }
        .onChange(of: experience.step) { announceStep() }
    }

    // MARK: - Pieces

    /// Outside the switch area, so a carer can always tap it. The language
    /// toggle in it is ALSO the last stop of every scan, so a switch user
    /// can reach Ukrainian without anyone's help.
    private var topBar: some View {
        TopBar(languageLit: scanner.isHighlighted(BoardID.language)) {
            if experience.step == .free {
                AskMenu()
            } else {
                GoalBanner(
                    isScanning: isScanning,
                    showMeLit: scanner.isHighlighted(BoardID.showMe),
                    guidesRow: guidesRow
                )
            }
        }
    }

    /// True while the guide's word sits in a "Something else" row the scan
    /// has not entered yet — the next press there picks the row.
    private var guidesRow: Bool {
        guard isScanning, let row = experience.guideRowIndex else { return false }
        return !scanner.isEntered(BoardID.miniRow(row))
    }

    private var headTryOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .switchTapArea(isActive: isScanning)
                .accessibilityHidden(true)
            // Core's panel pauses this board's scanner while it is shown and
            // routes presses back to it before `onDone`, so not a single
            // press falls between the two.
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
        // The handlers keep their own references, so they never depend on
        // this view value still being on screen.
        let story = experience
        scanner.bind(to: services, label: { id in
            BoardID.label(for: id)
        }, onSelect: { id in
            story.activate(id)
        })
        scanner.listen(to: hub)
        reload()
        announceStep()
    }

    private func reload() {
        settle?.cancel()
        let tree = experience.scanTree
        scanner.load(tree, start: false)
        guard isScanning, !tree.isEmpty else { return }
        let boardScanner = scanner
        settle = Task {
            try? await Task.sleep(for: .seconds(ConversationScreen.settleSeconds))
            guard !Task.isCancelled else { return }
            boardScanner.load(tree)
        }
    }

    /// Only the free board is announced here. In the guided story each turn
    /// announces itself — step, question and goal together — once the nurse
    /// has asked (`Experience.runTurn`), so the two never talk over each other.
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

#Preview("Free board") {
    let experience = Experience.preview(.free)
    return ConversationScreen()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
