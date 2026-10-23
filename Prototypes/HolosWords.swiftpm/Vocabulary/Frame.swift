import Foundation

/// The six sentence starters, in the order they sit on the board.
///
/// Raw values become part of every phrase id ("need.medicine"), so they
/// must never contain a dot.
enum FrameID: String, CaseIterable, Identifiable, Sendable {
    case need
    case feel
    case want
    case call
    case canYou
    case whereIs

    var id: String { rawValue }
}

/// A sentence starter ("I need…") and every sentence it can finish.
///
/// Why whole sentences, and not a starter glued to a word: Ukrainian
/// inflects. "Call my wife" is «Подзвоніть, будь ласка, моїй дружині» —
/// the word for wife, «дружина», changes its ending, and even "my" must
/// agree with it: «моїй дружині», but «моєму братові». So the starter
/// cannot hold "my" at all. "I need" is «Мені потрібен лікар» for a doctor,
/// «потрібна вода» for water and «потрібні ліки» for medicine. "I feel" +
/// "pain" is not a feeling verb at all: it is «Мені боляче». No rule an app
/// could run would get all of these right, and a person who has lost
/// their words deserves not to sound broken on top of it. So every filler
/// stores the complete, correct sentence in both languages, and the
/// vocabulary can be read — and corrected — line by line by a Ukrainian
/// speech therapist. That review is a step the real app cannot skip.
struct SentenceFrame: Identifiable, Sendable {
    let id: FrameID
    /// The chip: "I need…".
    let starter: Bilingual
    /// What stands before the blank in the sentence bar: "I need ____".
    let stem: Bilingual
    let symbol: String
    let kind: WordKind
    /// The eight words the board offers for this starter, most needed first.
    let fillers: [Phrase]
    /// Sentences this starter can make that do not fit on the board. Find a
    /// word reaches them: no board can hold every word, but every word a
    /// person finds still has to land in a correct sentence.
    let more: [Phrase]

    /// The sentence this starter makes with `concept`, if it makes one.
    func phrase(for concept: String) -> Phrase? {
        let wanted = Phrase.makeID(id, concept)
        return fillers.first { $0.id == wanted } ?? more.first { $0.id == wanted }
    }
}

extension Phrase {
    /// "need" + "medicine" → "need.medicine". The same concept keeps its
    /// name under every starter, which is how a word found by describing it
    /// finds the right sentence for whichever starter is open.
    static func makeID(_ frame: FrameID, _ concept: String) -> String {
        frame.rawValue + "." + concept
    }

    /// One filler: the word shown on the cell, and the whole sentence it says.
    static func filler(
        _ frame: FrameID,
        _ concept: String,
        _ label: Bilingual,
        says sentence: Bilingual,
        symbol: String,
        kind: WordKind
    ) -> Phrase {
        Phrase(makeID(frame, concept), label, says: sentence, symbol: symbol, kind: kind)
    }

    /// The starter this phrase belongs to, read back from its id.
    var frameID: FrameID? {
        guard let dot = id.firstIndex(of: ".") else { return nil }
        return FrameID(rawValue: String(id[..<dot]))
    }
}
