import SwiftUI

/// What kind of word a cell holds, colour-coded after the modified
/// Fitzgerald Key that speech therapists already use on paper boards.
///
/// The colours are a second route to the word for someone whose reading
/// has been taken by aphasia: "the green ones are things I can do" is
/// learnable even when the printed word is not. Every tint is pale enough
/// that black text on it stays above 7:1 contrast.
enum WordKind: String, CaseIterable, Sendable {
    /// Greetings, please, thank you.
    case social
    /// I, you, family, staff.
    case people
    /// Verbs.
    case action
    /// Feelings and descriptions.
    case describing
    /// Nouns.
    case thing
    /// What, where, when.
    case question
    /// Help, pain, no — red, because these must be found fastest.
    case urgent
    /// Speak, delete, back: the board's own controls.
    case control

    var tint: Color {
        switch self {
        case .social: Color(red: 0.99, green: 0.84, blue: 0.90)
        case .people: Color(red: 1.00, green: 0.93, blue: 0.62)
        case .action: Color(red: 0.78, green: 0.93, blue: 0.76)
        case .describing: Color(red: 0.78, green: 0.88, blue: 1.00)
        case .thing: Color(red: 1.00, green: 0.85, blue: 0.68)
        case .question: Color(red: 0.88, green: 0.82, blue: 0.98)
        case .urgent: Color(red: 1.00, green: 0.76, blue: 0.74)
        case .control: Color(red: 0.88, green: 0.89, blue: 0.91)
        }
    }

    /// A darker sibling of the tint, for outlines and icons on light cells.
    var ink: Color {
        switch self {
        case .social: Color(red: 0.62, green: 0.10, blue: 0.36)
        case .people: Color(red: 0.48, green: 0.36, blue: 0.00)
        case .action: Color(red: 0.12, green: 0.42, blue: 0.14)
        case .describing: Color(red: 0.10, green: 0.30, blue: 0.62)
        case .thing: Color(red: 0.60, green: 0.30, blue: 0.02)
        case .question: Color(red: 0.36, green: 0.20, blue: 0.62)
        case .urgent: Color(red: 0.66, green: 0.08, blue: 0.08)
        case .control: Color(red: 0.25, green: 0.27, blue: 0.30)
        }
    }
}

/// One cell on a board: a picture, a short word, and what to say aloud.
///
/// The label and the speech are deliberately separate. A cell reads
/// "Water" so it can be recognised at a glance, but says "Water, please."
/// so the listener hears a whole, polite request — the person using the
/// board should never sound more abrupt than they are.
struct Phrase: Identifiable, Hashable, Sendable {
    let id: String
    /// One to three words, shown on the cell.
    let label: Bilingual
    /// What the voice says when the cell is spoken or added to a message.
    let speech: Bilingual
    /// An SF Symbol name. A placeholder: the real app swaps in ARASAAC
    /// pictograms, which are drawn for exactly this use.
    let symbol: String
    let kind: WordKind

    init(_ id: String, _ label: Bilingual, says speech: Bilingual? = nil, symbol: String, kind: WordKind) {
        self.id = id
        self.label = label
        self.speech = speech ?? label
        self.symbol = symbol
        self.kind = kind
    }
}
