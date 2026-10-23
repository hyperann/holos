import SwiftUI

/// The warm look of Bedside: cream paper, terracotta, soft shadows.
///
/// A hospital room is all white and steel; this board should feel like the
/// person's own notebook instead. Every colour that carries text is checked
/// for contrast: small text uses `rust` (about 6:1 on cream), and with
/// Increase Contrast the terracotta bubbles darken to well past 7:1.
enum BedsideTheme {
    static let background = Color(red: 0.99, green: 0.96, blue: 0.91)
    static let chatBackground = Color(red: 0.97, green: 0.92, blue: 0.85)
    static let card = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let terracotta = Color(red: 0.72, green: 0.33, blue: 0.22)
    /// Terracotta deep enough for small text and for Increase Contrast.
    static let rust = Color(red: 0.56, green: 0.22, blue: 0.13)
    static let peach = Color(red: 1.0, green: 0.86, blue: 0.76)
    static let softInk = Color(red: 0.35, green: 0.29, blue: 0.26)
    static let outline = Color(red: 0.80, green: 0.68, blue: 0.60)
    static let shadow = Color(red: 0.45, green: 0.25, blue: 0.15).opacity(0.14)

    /// Fill for the person's own bubbles.
    static func personBubble(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? rust : terracotta
    }

    /// Outline for cards and bubbles: soft normally, ink-dark when the
    /// person has asked for more contrast.
    static func line(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? HolosTheme.ink : outline
    }
}

/// Body text set in SF Rounded, so the whole board reads as one voice.
extension Font {
    static func bedside(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}
