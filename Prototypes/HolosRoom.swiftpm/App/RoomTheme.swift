import SwiftUI

/// The colours of everything around the room: the dusk backdrop, the
/// cards, the chips.
///
/// The room is drawn at dusk, so the chrome is dark too — a bright frame
/// around a dim scene would pull the eye away from the spotlight. Text on
/// it is white, and cards are paper-white with near-black ink, both well
/// above 7:1. Increase Contrast swaps the soft translucent fills for solid
/// ones.
enum RoomTheme {
    static func backdrop(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? .black : Color(red: 0.03, green: 0.10, blue: 0.12)
    }

    /// The shelf the chips and the message strip sit on.
    static func shelf(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? Color(red: 0.10, green: 0.12, blue: 0.13) : Color(red: 0.07, green: 0.19, blue: 0.21)
    }

    static func chip(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? Color(red: 0.18, green: 0.20, blue: 0.22) : Color.white.opacity(0.12)
    }

    static func outline(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? Color.white.opacity(0.85) : Color.white.opacity(0.2)
    }

    /// Secondary text on the dark backdrop.
    static func quiet(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? .white : Color.white.opacity(0.78)
    }

    static let card = Color(red: 0.98, green: 0.97, blue: 0.94)
    /// The person's own speech bubble: warm, like the lamp light.
    static let voice = Color(red: 1.0, green: 0.93, blue: 0.70)
}
