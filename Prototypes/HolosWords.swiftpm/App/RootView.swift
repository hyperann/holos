import SwiftUI

/// One screen per step of the tour. The two board steps and free use share
/// a single board screen, so moving between them never rebuilds the board.
struct RootView: View {
    @Environment(Experience.self) private var experience
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            WordsTheme.page(contrast)
                .ignoresSafeArea()
            content
        }
        // Steps cross-fade: a fade, not a slide, so Reduce Motion needs no
        // separate path.
        .animation(.easeInOut(duration: 0.3), value: experience.step)
        .switchKeys()
        .switchPressFlash()
        // The notebook look is designed for paper: the Fitzgerald tints and
        // the ink are tuned for a light page.
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var content: some View {
        switch experience.step {
        case .problem:
            ProblemStep()
        case .twoChoices, .findWord, .free:
            BoardScreen()
        case .headTry:
            HeadTryStep()
        case .ukrainian:
            UkrainianStep()
        case .closing:
            ClosingStep()
        }
    }
}

#Preview("Holos Words") {
    RootView()
        .environment(Experience())
        .holos(.preview())
}
