import SwiftUI

/// The shared colours every prototype relies on for legibility.
///
/// Prototypes are free to look different; these few are shared because
/// they carry meaning. The highlight is one colour everywhere so that "lit"
/// always looks the same, and it is drawn as a thick yellow ring with a
/// black keyline on both sides, which stays visible on white, black and
/// every Fitzgerald tint alike.
enum HolosTheme {
    static let highlight = Color(red: 1.0, green: 0.80, blue: 0.0)
    static let keyline = Color.black
    static let ink = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let paper = Color.white
}

extension View {
    /// Draws the scan highlight around this view while `isOn`.
    func scanHighlight(_ isOn: Bool, cornerRadius: CGFloat = 18) -> some View {
        modifier(ScanHighlightModifier(isOn: isOn, cornerRadius: cornerRadius))
    }
}

private struct ScanHighlightModifier: ViewModifier {
    let isOn: Bool
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isOn {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(HolosTheme.keyline, lineWidth: 11)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .inset(by: 2)
                            .strokeBorder(HolosTheme.highlight, lineWidth: 7)
                    }
                    .allowsHitTesting(false)
                }
            }
            // A small lift helps the eye find the lit cell from across a
            // room. With Reduce Motion the ring alone does the job.
            .scaleEffect(isOn && !reduceMotion ? 1.04 : 1)
            .zIndex(isOn ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isOn)
    }
}
