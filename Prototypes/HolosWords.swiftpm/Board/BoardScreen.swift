import SwiftUI

/// The board: sentence bar, starters, the words that fit, and Find a word.
///
/// The same screen serves both guided steps of the tour and free use
/// afterwards — the tour only adds a goal banner on top. What a judge
/// learns in steps 2 and 3 is exactly the real app.
struct BoardScreen: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let board = experience.board
        GeometryReader { proxy in
            let width = proxy.size.width
            let compact = width < 600
            VStack(spacing: 10) {
                TopBar(showsRestart: experience.step == .free)
                VoiceNotice()
                VStack(spacing: 12) {
                    if let goal = board.goal {
                        GoalBanner(goal: goal, isScanning: isScanning, compact: compact)
                    }
                    SentenceBar(isScanning: isScanning, compact: compact)
                    if let screen = board.findScreen {
                        FindPanel(screen: screen, isScanning: isScanning, perRow: findColumns(width: width))
                    } else {
                        StarterRow(columns: starterColumns(width: width), isScanning: isScanning, compact: compact)
                        FillerGrid(isScanning: isScanning, compact: compact)
                        FindStrip(compact: compact)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                // The board area is the switch; the top bar stays tappable.
                .switchTapArea(isActive: isScanning)
            }
            .padding(.horizontal, compact ? 12 : 20)
            .padding(.vertical, 12)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        // The cells are already large and scale their own words down; past
        // this size the grid would push whole rows off the screen. Settings
        // and the reading screens are not capped.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .onAppear {
            board.connect(services)
            board.scanner.listen(to: hub)
            board.setScanActive(isScanning)
        }
        .onDisappear {
            board.leave()
        }
        .onChange(of: isScanning) {
            board.setScanActive(isScanning)
        }
    }

    /// One row of eight on a wide iPad; two rows of four elsewhere — iPhone
    /// included, where the pills simply get narrower.
    private func starterColumns(width: CGFloat) -> Int {
        let count = FrameID.allCases.count + 1 + (isScanning ? 1 : 0)
        return width >= 1100 ? count : 4
    }

    private func findColumns(width: CGFloat) -> Int {
        if width >= 900 { return 6 }
        return width >= 600 ? 3 : 2
    }
}

#Preview("Board — step 2") {
    let experience = Experience()
    experience.show(.twoChoices)
    return BoardScreen()
        .environment(experience)
        .holos(.preview())
}

#Preview("Board — free") {
    let experience = Experience()
    experience.show(.free)
    return BoardScreen()
        .environment(experience)
        .holos(.preview())
}
