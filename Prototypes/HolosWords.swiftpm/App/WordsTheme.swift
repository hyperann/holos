import SwiftUI

/// The look of Holos Words: a good notebook. Warm paper, ink, a red margin
/// line, and the sentence written large — calm enough to think on, because
/// finding a word is hard work and the screen should not add to it.
///
/// Every colour here sits under black or ink text at well above 7:1, and
/// Increase Contrast swaps the warm paper for plain white.
enum WordsTheme {
    static let paper = Color(red: 0.980, green: 0.961, blue: 0.918)
    /// The slightly darker paper behind each scanned row.
    static let paperDeep = Color(red: 0.937, green: 0.910, blue: 0.847)
    /// Faint blue, like the printed lines of an exercise book.
    static let rule = Color(red: 0.55, green: 0.64, blue: 0.78)
    static let margin = Color(red: 0.80, green: 0.28, blue: 0.28)
    /// Secondary text: soft, but still 6.8:1 on paper.
    static let pencil = Color(red: 0.33, green: 0.31, blue: 0.28)

    static func page(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? .white : paper
    }

    static func secondary(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? HolosTheme.ink : pencil
    }
}
