import SwiftUI

/// The small "Next" tag on the choice that leads towards the goal.
///
/// It is deliberately small and sits in a corner: the yellow scan ring must
/// stay the loudest thing on screen, and a guide that shouted would teach
/// people to follow the guide rather than the light. Black and white, so it
/// can never be mistaken for the highlight.
struct GuideMarker: View {
    @Environment(HolosSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 15, weight: .bold))
            Copy.Board.next.text(settings.language)
                .font(CompassTheme.font(.subheadline))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(HolosTheme.ink, in: Capsule())
        .overlay { Capsule().strokeBorder(Color.white, lineWidth: 2) }
        // A slow, small breath draws the eye without moving the layout.
        // Reduce Motion keeps it perfectly still.
        .scaleEffect(pulsing && !reduceMotion ? 1.08 : 1)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: pulsing
        )
        .onAppear { pulsing = true }
        // The petal says "Suggested next" in its own value.
        .accessibilityHidden(true)
    }
}

#Preview("Guide marker") {
    GuideMarker()
        .padding()
        .background(WordKind.thing.tint)
        .holos(.preview())
}
