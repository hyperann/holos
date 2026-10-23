import SwiftUI

/// The small yellow arrow over the next thing to press in a guided step.
///
/// It sits on whatever leads to the goal from where the person is now — a
/// hotspot, a phrase, or "Go back" if they wandered — so a judge who has
/// never seen a scanner always knows what the light is waiting for. It
/// bobs gently; under Reduce Motion it stays still.
struct GuideMarker: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // A plain number, so the animation closure captures nothing else.
        let lift: CGFloat = reduceMotion ? 0 : -6
        Image(systemName: "arrow.down")
            .font(.system(size: 17, weight: .black))
            .foregroundStyle(HolosTheme.ink)
            .frame(width: 34, height: 34)
            .background(HolosTheme.highlight, in: Circle())
            .overlay { Circle().strokeBorder(HolosTheme.keyline, lineWidth: 2.5) }
            .phaseAnimator([false, true]) { content, raised in
                content.offset(y: raised ? lift : 0)
            } animation: { _ in
                .easeInOut(duration: 0.7)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Guide marker") {
    GuideMarker()
        .padding(40)
        .background(Color.teal)
}
