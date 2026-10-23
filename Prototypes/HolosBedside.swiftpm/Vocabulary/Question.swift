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
    /// prediction is a help, never a cage. When an open question already
    /// leads with "Something else", it is not offered twice.
    var strip: [Phrase] {
        let main = Set(answers.map(\.id))
        return Vocabulary.strip.filter { !main.contains($0.id) }
    }
}

/// The three topics of the "Something else" board.
enum MiniTopic: String, CaseIterable, Identifiable, Sendable {
    case needs
    case feelings
    case talk

    var id: String { rawValue }

    var title: Bilingual {
        switch self {
        case .needs: Copy.topicNeeds
        case .feelings: Copy.topicFeelings
        case .talk: Copy.topicTalk
        }
    }

    var symbol: String {
        switch self {
        case .needs: "cup.and.saucer.fill"
        case .feelings: "face.smiling"
        case .talk: "bubble.left.and.bubble.right.fill"
        }
    }

    /// Two rows of four: small enough to scan row by row in a few presses.
    var rows: [[Phrase]] { Vocabulary.rows(for: self) }

    private static let scanPrefix = "mini.topic."

    /// The topic's tab, as the scanner knows it.
    var scanID: String { Self.scanPrefix + rawValue }

    init?(scanID: String) {
        guard scanID.hasPrefix(Self.scanPrefix) else { return nil }
        self.init(rawValue: String(scanID.dropFirst(Self.scanPrefix.count)))
    }

    /// The topic holding a phrase, if it lives on the mini board at all.
    static func containing(_ phraseID: String) -> MiniTopic? {
        allCases.first { topic in
            topic.rows.contains { row in row.contains { $0.id == phraseID } }
        }
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
    static let miniClose = "mini.close"

    static func miniRow(_ index: Int) -> String { "mini.row\(index)" }

    /// The words for an id, for auditory prompts (quietly reading each lit
    /// item aloud). Back cells are voiced by Core.
    static func label(for id: String) -> Bilingual? {
        if let phrase = Vocabulary.phrase(id: id) { return phrase.label }
        if let topic = MiniTopic(scanID: id) { return topic.title }
        if id == language { return CoreCopy.languageLabel }
        if id == showMe { return Copy.showMe }
        if id == miniClose { return Copy.backToAnswers }
        if id == miniRow(0) { return Copy.topRow }
        if id == miniRow(1) { return Copy.bottomRow }
        return nil
    }
}
