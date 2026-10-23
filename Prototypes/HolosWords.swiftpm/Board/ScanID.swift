import Foundation

/// The ids the board's scan is built from — one place, so the tree, the
/// views that draw the highlight and the selection handler can never
/// disagree about a spelling.
enum ScanID {
    // The sentence bar row.
    static let sentenceRow = "row.sentence"
    static let speak = "sentence.speak"
    static let delete = "sentence.delete"
    /// A group when scanned, as in Core's message bar: a late press must
    /// never wipe a message that took minutes to build. The first press
    /// opens Clear on "No, keep it", so a double press keeps the message;
    /// only "Yes, clear all", lit a full step later, clears.
    static let clear = "sentence.clear"
    static let clearCancel = "sentence.clear.cancel"
    static let clearConfirm = "sentence.clear.confirm"

    // The starters row.
    static let startersRow = "row.starters"
    static let language = "board.language"
    static let starterPrefix = "starter."

    // The filler rows and Find a word.
    static let fillerRowPrefix = "row.fillers."
    static let fillerPrefix = "filler."
    static let findOpen = "find.open"
    static let findBack = "find.back"
    static let findOptionPrefix = "find.option."

    // The guide's way out when someone is stuck.
    static let showMe = "guide.showMe"
    static let skip = "guide.skip"

    static func starter(_ frame: FrameID) -> String { starterPrefix + frame.rawValue }
    static func fillerRow(_ index: Int) -> String { fillerRowPrefix + String(index) }
    static func filler(_ phraseID: String) -> String { fillerPrefix + phraseID }
    static func findOption(_ option: FindOption) -> String { findOptionPrefix + option.id }
    static func findCategory(_ categoryID: String) -> String { findOptionPrefix + FindOption.key(category: categoryID) }
    static func findWord(_ concept: String) -> String { findOptionPrefix + FindOption.key(word: concept) }
}

extension String {
    /// The rest of the string after `prefix`, or nil if it does not start with it.
    func dropping(prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}
