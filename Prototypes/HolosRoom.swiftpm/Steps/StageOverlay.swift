import SwiftUI

/// Whichever card the story needs now, over the bottom of the room.
///
/// The room never leaves the screen: cards come and go over it, so the
/// judge stays in one place from the nurse's question to the closing words
/// — the same room they will keep talking in afterwards.
struct StageOverlay: View {
    let isNarrow: Bool

    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let arrive: AnyTransition = reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
        ZStack(alignment: .bottom) {
            card
                .id(experience.stage)
                .transition(arrive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(
            reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.45, dampingFraction: 0.86),
            value: experience.stage
        )
    }

    @ViewBuilder
    private var card: some View {
        switch experience.stage {
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone:
            if let title = experience.cardTitle, let message = experience.cardBody {
                StageCard(title: title, message: message, isNarrow: isNarrow)
            }
        case .headTry:
            // Core's shared panel: it routes the switch itself while shown,
            // lights Skip first, and hands back through `headTryDone()`.
            HeadTryPanel {
                experience.headTryDone()
            }
            // Light, like every other card in the story.
            .environment(\.colorScheme, .light)
            .shadow(color: .black.opacity(0.45), radius: 24, y: 10)
        case .ukrainian:
            UkrainianCard(isNarrow: isNarrow)
        case .closing:
            ClosingCard(isNarrow: isNarrow)
        case .scanRoom, .familiar, .free:
            EmptyView()
        }
    }
}

#Preview("Stage overlay") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return StageOverlay(isNarrow: false)
        .padding()
        .background(Color(red: 0.03, green: 0.10, blue: 0.12))
        .holos(services)
        .environment(experience)
        .onAppear { experience.start(isScanning: true) }
}
