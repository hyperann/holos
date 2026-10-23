import SwiftUI

/// Shows the step the story is on.
///
/// The switch keys and the press flash are applied once here, so every
/// screen gets them and no screen can forget them.
struct RootView: View {
    @Environment(Experience.self) private var experience

    var body: some View {
        ZStack {
            BedsideTheme.background
                .ignoresSafeArea()
            content
                .transition(.opacity)
        }
        // A fade between steps is not movement, so it stays on even with
        // Reduce Motion.
        .animation(.easeInOut(duration: 0.35), value: experience.step)
        .switchKeys()
        .switchPressFlash()
        // The cream-and-terracotta palette is part of the concept and has
        // been contrast-checked as a light palette; a dark board would need
        // its own checked palette, which is listed as an open question.
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var content: some View {
        switch experience.step {
        case .problem:
            ProblemStep()
        case .conversation, .free:
            ConversationScreen()
        case .ukrainian:
            ReplayStep()
        case .closing:
            ClosingStep()
        }
    }
}

#Preview("Root") {
    let experience = Experience.preview(.problem)
    return RootView()
        .environment(experience)
        .holos(experience.services)
}
