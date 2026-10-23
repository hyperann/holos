import SwiftUI

/// Compass is dark on purpose.
///
/// The people it is for are often lying down, often with blurred or tired
/// vision after a brain injury, often in a ward where lights are dimmed at
/// night. Near-black around four pale, bright petals puts all the contrast
/// where the choices are, and nothing anywhere else competes for the eye.
enum CompassTheme {
    static let background = Color(red: 0.04, green: 0.045, blue: 0.055)
    /// Cards and the centre hub: lifted just enough off the background to
    /// read as surfaces.
    static let surface = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let surfaceRaised = Color(red: 0.18, green: 0.19, blue: 0.22)
    static let text = Color.white
    /// Secondary text stays well above 7:1 on the background.
    static let quietText = Color(red: 0.78, green: 0.80, blue: 0.84)

    /// The outline around dark surfaces; solid white under Increase Contrast.
    static func keyline(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? Color.white : Color.white.opacity(0.22)
    }

    static func keylineWidth(_ contrast: ColorSchemeContrast) -> CGFloat {
        contrast == .increased ? 2.5 : 1.5
    }

    /// The face every label on the compass uses: rounded, heavy, readable
    /// from a pillow.
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .heavy) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}
