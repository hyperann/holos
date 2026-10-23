import Accessibility
import Foundation

/// The two languages Holos speaks.
///
/// Ukrainian is the reason the app exists. English is the default because
/// the Swift Student Challenge asks for English content — and because the
/// same board has to work in a Kyiv hospital and a UK clinic. Every phrase
/// carries both, so switching is one tap, never a reload.
enum Language: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case ukrainian = "uk"

    var id: String { rawValue }

    /// The tag VoiceOver and the speech synthesizer use to choose a voice.
    var localeIdentifier: String {
        switch self {
        case .english: "en-US"
        case .ukrainian: "uk-UA"
        }
    }

    /// The language's name in itself. A Ukrainian speaker scanning for
    /// their language should find "Українська", not "Ukrainian".
    var nativeName: String {
        switch self {
        case .english: "English"
        case .ukrainian: "Українська"
        }
    }

    /// Short form for a toggle chip.
    var shortName: String {
        switch self {
        case .english: "EN"
        case .ukrainian: "УКР"
        }
    }

    var other: Language {
        switch self {
        case .english: .ukrainian
        case .ukrainian: .english
        }
    }
}

/// Ukrainian marks the speaker's gender in past-tense verbs and many
/// adjectives — "я втомився" when a man is tired, "я втомилася" when a
/// woman is. English never does. An app that speaks *for* someone has to
/// get this right, or every tired sentence misgenders the person saying it.
enum SpeakerGender: String, CaseIterable, Identifiable, Sendable {
    case masculine
    case feminine

    var id: String { rawValue }
}

/// One piece of text in both languages.
///
/// Call it like a function to read it: `words(.ukrainian, .feminine)`.
struct Bilingual: Hashable, Sendable {
    let en: String
    let uk: String
    /// Only where Ukrainian grammar needs it: the form a woman would say.
    /// `nil` means the masculine form is already gender-neutral.
    let ukFeminine: String?

    init(_ en: String, uk: String, ukFeminine: String? = nil) {
        self.en = en
        self.uk = uk
        self.ukFeminine = ukFeminine
    }

    func callAsFunction(_ language: Language, _ gender: SpeakerGender = .masculine) -> String {
        switch language {
        case .english:
            en
        case .ukrainian:
            gender == .feminine ? (ukFeminine ?? uk) : uk
        }
    }

    /// The text tagged with its language, for accessibility labels.
    ///
    /// Without the tag, VoiceOver hands Cyrillic to whatever voice the
    /// user's VoiceOver is set to — and an English voice sounding out
    /// Ukrainian is not accented, it is unintelligible.
    func spoken(_ language: Language, _ gender: SpeakerGender = .masculine) -> AttributedString {
        var string = AttributedString(self(language, gender))
        string.languageIdentifier = language.localeIdentifier
        return string
    }

    /// Joins several pieces into one, keeping each language (and each
    /// gendered form) aligned.
    static func joined(_ parts: [Bilingual], separator: String = " ") -> Bilingual {
        Bilingual(
            parts.map(\.en).joined(separator: separator),
            uk: parts.map(\.uk).joined(separator: separator),
            ukFeminine: parts.contains { $0.ukFeminine != nil }
                ? parts.map { $0.ukFeminine ?? $0.uk }.joined(separator: separator)
                : nil
        )
    }
}

/// Posts a VoiceOver announcement at HIGH priority, tagged with its language.
///
/// Default-priority announcements are silently dropped when they race
/// VoiceOver's own readouts (a finding carried over from Vidkryto), so
/// every announcement in Holos goes through here.
@MainActor
func announce(_ text: String, in language: Language) {
    var string = AttributedString(text)
    string.languageIdentifier = language.localeIdentifier
    string.accessibilitySpeechAnnouncementPriority = .high
    AccessibilityNotification.Announcement(string).post()
}
