import Foundation
import Observation

/// The sentence being built, one cell at a time.
///
/// It holds phrases rather than text so that switching language rewrites
/// the whole message at once: build "I'm in pain. Medicine, please." in
/// English, tap УКР, and the same message is ready to speak in Ukrainian.
@MainActor
@Observable
final class MessageBuilder {
    private(set) var phrases: [Phrase] = []

    /// Long enough for any real sentence; short enough that a mis-scan
    /// loop can never fill the bar with dozens of cells.
    let capacity = 12

    var isEmpty: Bool { phrases.isEmpty }
    var isFull: Bool { phrases.count >= capacity }

    /// The whole message in both languages.
    var words: Bilingual { Bilingual.joined(phrases.map(\.speech)) }

    /// Returns false when the message is full, so a caller can answer with
    /// `Feedback.unavailable()` instead of a success it did not earn.
    @discardableResult
    func add(_ phrase: Phrase) -> Bool {
        guard !isFull else { return false }
        phrases.append(phrase)
        return true
    }

    func removeLast() {
        guard !phrases.isEmpty else { return }
        phrases.removeLast()
    }

    func clear() {
        phrases.removeAll()
    }

    func text(_ language: Language, _ gender: SpeakerGender) -> String {
        words(language, gender)
    }
}
