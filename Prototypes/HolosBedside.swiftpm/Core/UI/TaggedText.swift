import SwiftUI

extension Bilingual {
    /// A `Text` tagged with its language. Use it for every visible label and
    /// every accessibility label, value and hint: VoiceOver reads visible text
    /// too, and Ukrainian handed to an English voice is not accented, it is
    /// unintelligible.
    func text(_ language: Language, _ gender: SpeakerGender = .masculine) -> Text {
        Text(spoken(language, gender))
    }

    /// Every form of these words, English first, for Voice Control.
    ///
    /// Voice Control may not recognise Ukrainian at all, so a carer must be
    /// able to say the English name of a cell even while the board shows
    /// Ukrainian — and a Ukrainian speaker the Ukrainian one where it can.
    /// The first label is the one "Show names" displays.
    var inputLabels: [Text] {
        var seen = Set<String>()
        return [en, uk, ukFeminine]
            .compactMap { $0 }
            .filter { seen.insert($0).inserted }
            .map { Text($0) }
    }
}

/// A `Text` for a string that is already in one language — a number with
/// its unit, a voice name — tagged so VoiceOver picks the right voice.
func taggedText(_ string: String, _ language: Language) -> Text {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language.localeIdentifier
    return Text(attributed)
}
