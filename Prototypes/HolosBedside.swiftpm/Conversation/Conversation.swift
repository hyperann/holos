import Foundation
import Observation

/// Who a line in the conversation belongs to.
enum ChatRole: Sendable {
    /// The nurse in the guided story.
    case nurse
    /// Any communication partner in free conversation: a carer, a doctor.
    case partner
    /// The person using Holos. Only these lines are ever spoken aloud.
    case person
    /// A quiet stage direction: "Ten minutes later".
    case note
}

/// One line of the conversation.
///
/// It keeps the `Bilingual` words rather than a rendered string, so the
/// same transcript can be redrawn — and re-spoken — in Ukrainian at the
/// end without anything being translated after the fact.
struct ChatLine: Identifiable, Equatable, Sendable {
    let id: Int
    let role: ChatRole
    let words: Bilingual
    /// The picture of the answer, for the person's own bubbles.
    let symbol: String?
    /// For a pain-scale answer, the face it was chosen by (0…3), drawn in
    /// the bubble instead of a symbol — so the record shows what the person
    /// picked, never a number they did not.
    let faceLevel: Int?

    init(id: Int, role: ChatRole, words: Bilingual, symbol: String?, faceLevel: Int? = nil) {
        self.id = id
        self.role = role
        self.words = words
        self.symbol = symbol
        self.faceLevel = faceLevel
    }
}

/// The conversation on screen, and what the board is offering right now.
///
/// It holds state only; the order of events (who speaks when) belongs to
/// `Experience` in the guided story, and to the partner's taps in free
/// conversation.
@MainActor
@Observable
final class Conversation {
    private(set) var lines: [ChatLine] = []
    /// The question the answer cells belong to.
    private(set) var question: Question = .feeling
    /// The question exactly as it was asked, which can differ from the
    /// card's wording ("I'm back. How are you feeling now?").
    private(set) var prompt: Bilingual?
    /// While the partner is talking the board waits: no scanning, cells
    /// dimmed. A conversation has turns, and the board respects them.
    var isPartnerTurn = false
    /// The partner is "typing" — shown as three dots.
    var isTyping = false
    private(set) var isMiniBoardOpen = false
    private(set) var miniTopic: MiniTopic = .needs

    @ObservationIgnored private var nextID = 0

    var personLines: [ChatLine] {
        lines.filter { $0.role == .person }
    }

    func append(_ role: ChatRole, _ words: Bilingual, symbol: String? = nil, faceLevel: Int? = nil) {
        lines.append(ChatLine(id: nextID, role: role, words: words, symbol: symbol, faceLevel: faceLevel))
        nextID += 1
    }

    /// The person's answer, as the whole sentence it speaks.
    func addPerson(_ phrase: Phrase) {
        let faceLevel = Vocabulary.scale.firstIndex { $0.id == phrase.id }
        append(.person, phrase.speech, symbol: phrase.symbol, faceLevel: faceLevel)
    }

    /// Changes the answers on the board to fit `question`.
    func setQuestion(_ question: Question, prompt: Bilingual?) {
        self.question = question
        self.prompt = prompt
        isMiniBoardOpen = false
    }

    func openMiniBoard() {
        // Always the same first topic, so the board is learnable: Needs is
        // where most bedside requests live.
        miniTopic = .needs
        isMiniBoardOpen = true
    }

    func closeMiniBoard() {
        isMiniBoardOpen = false
    }

    func showTopic(_ topic: MiniTopic) {
        miniTopic = topic
    }

    func reset() {
        lines.removeAll()
        question = .feeling
        prompt = nil
        isPartnerTurn = false
        isTyping = false
        isMiniBoardOpen = false
        miniTopic = .needs
    }
}
