/// How a question's answers are laid out on the board.
enum AnswerLayout: Sendable {
    /// Up to six big picture cells.
    case cells
    /// A body to point at, with a labelled cell for every region.
    case bodyMap
    /// An ordered scale with faces, smallest first.
    case scale
}

/// A question the communication partner can ask.
///
/// This is the heart of the Bedside idea, borrowed from Supported
/// Conversation for Adults with Aphasia: the partner does the asking, and
/// the board answers with only the handful of replies that fit THAT
/// question. Six choices instead of sixty means far less to scan, and far
/// less to hold in mind for someone whose language is damaged.
enum Question: String, CaseIterable, Identifiable, Sendable {
    case feeling
    case painWhere
    case painHowBad
    case needs
    case whoToCall
    case rest
    case anythingElse

    var id: String { rawValue }

    /// The question as the partner asks it.
    var prompt: Bilingual {
        switch self {
        case .feeling: Copy.qFeeling
        case .painWhere: Copy.qWhere
        case .painHowBad: Copy.qHowBad
        case .needs: Copy.qNeeds
        case .whoToCall: Copy.qCall
        case .rest: Copy.qRest
        case .anythingElse: Copy.qTell
        }
    }

    /// The picture on the partner's question card.
    var symbol: String {
        switch self {
        case .feeling: "face.smiling"
        case .painWhere: "figure.stand"
        case .painHowBad: "thermometer.medium"
        case .needs: "cup.and.saucer.fill"
        case .whoToCall: "phone.fill"
        case .rest: "bed.double.fill"
        case .anythingElse: "ellipsis.bubble.fill"
        }
    }

    var layout: AnswerLayout {
        switch self {
        case .painWhere: .bodyMap
        case .painHowBad: .scale
        default: .cells
        }
    }

    /// The predicted answers, most likely first: in linear scanning every
    /// place further down the list costs another 1.4 seconds of waiting.
    var answers: [Phrase] { Vocabulary.answers(for: self) }

    /// Yes · No · Not sure · Something else, under every question — the
    /// prediction is a help, never a cage, and "Something else" opens the
    /// whole board. When an open question already leads with "Something
    /// else", it is not offered twice.
    var strip: [Phrase] {
        let main = Set(answers.map(\.id))
        return Vocabulary.strip.filter { !main.contains($0.id) }
    }
}

/// The six places that can hurt on the body map.
enum BodyRegion: String, CaseIterable, Identifiable, Sendable {
    case head
    case chest
    case stomach
    case back
    case arm
    case leg

    var id: String { rawValue }

    /// The answer cell that speaks for this region.
    var phraseID: String { "body." + rawValue }

    init?(phraseID: String) {
        guard phraseID.hasPrefix("body.") else { return nil }
        self.init(rawValue: String(phraseID.dropFirst("body.".count)))
    }
}

/// Ids for the scan items that are not phrases.
enum BoardID {
    static let language = "board.language"
    static let showMe = "board.showMe"

    /// The words for an id, for auditory prompts (quietly reading each lit
    /// item aloud). Back cells are voiced by Core.
    static func label(for id: String) -> Bilingual? {
        if let phrase = Vocabulary.phrase(id: id) { return phrase.label }
        if id == language { return CoreCopy.languageLabel }
        if id == showMe { return Copy.showMe }
        return nil
    }
}
