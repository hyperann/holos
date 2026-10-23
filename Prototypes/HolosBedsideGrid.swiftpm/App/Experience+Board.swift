import Foundation

/// What the screen shows, worked out from where the story is.
///
/// Read-only views of `Experience`'s state, kept apart from the timing
/// code so each file reads as one idea.
@MainActor
extension Experience {
    var currentTurn: NurseTurn? {
        guard step == .conversation, NurseScript.turns.indices.contains(turnIndex) else { return nil }
        return NurseScript.turns[turnIndex]
    }

    /// The one answer the guide marker sits on. When the turn's word lives
    /// on the whole board, the marker sits on "Something else"; once the
    /// board is open, `boardGuideTarget` takes over. When the word is with
    /// the answers but the board is open, it sits on "Back to the answers".
    var guideID: String? {
        guard let turn = currentTurn, !conversation.isPartnerTurn, !isShowingHeadTry else { return nil }
        if BoardVocabulary.phrase(id: turn.target) != nil {
            return conversation.isBoardOpen ? nil : Vocabulary.somethingElse.id
        }
        return conversation.isBoardOpen ? GridIDs.back : turn.target
    }

    /// The whole board's goal for this turn: its word and the topic it is
    /// on, when the word lives there.
    var boardGuide: Guide? {
        guard let turn = currentTurn,
              let phrase = BoardVocabulary.phrase(id: turn.target),
              let topic = Topic.containing(phrase.id)
        else { return nil }
        return Guide(stops: [Guide.Stop(phrase: phrase, topic: topic)])
    }

    /// Where the whole board's "This one" tag goes: the topic, the word, or
    /// Speak — only while a turn is guiding there.
    var boardGuideTarget: GuideTarget? {
        guard currentTurn != nil, conversation.isBoardOpen,
              !conversation.isPartnerTurn, !isShowingHeadTry
        else { return nil }
        return board.guideTarget
    }

    /// True while the whole board is on screen and its scan should run.
    var wholeBoardIsLive: Bool {
        (step == .conversation || step == .free)
            && conversation.showsWholeBoard
            && !conversation.isPartnerTurn
            && !isShowingHeadTry
    }

    /// The banner's second line, following the guide. `compact` asks for
    /// the phone version, which has room for two lines; `scanning` for the
    /// words that name a row first, because on the whole board a press
    /// picks a row before it picks a word.
    func guideDetail(compact: Bool, scanning: Bool) -> Bilingual? {
        guard let turn = currentTurn else { return nil }
        guard conversation.isBoardOpen else {
            return compact ? (turn.compactDetail ?? turn.detail) : turn.detail
        }
        guard let guide = board.guide, let target = board.guideTarget else {
            return Copy.guideBackToAnswers
        }
        switch target {
        case .topic(let topic): return Copy.guideTopic(topic, scanning: scanning)
        case .cell(let phrase, _): return Copy.guideCell(phrase, scanning: scanning)
        case .speak: return Copy.guideSpeak(guide.phrases, scanning: scanning)
        }
    }

    /// Everything the switch can reach among the answers, in scan order.
    /// Empty while the whole board is showing: it scans by itself.
    ///
    /// Linear, not row-column: with six answers or fewer, one press per
    /// choice beats two, and there is nothing to hold in mind. The language
    /// switch is always last, so a switch-only person can reach Ukrainian.
    var scanTree: [ScanNode] {
        guard step == .conversation || step == .free else { return [] }
        guard !conversation.isPartnerTurn, !isShowingHeadTry, !conversation.showsWholeBoard else { return [] }
        var nodes: [ScanNode] = []
        if step == .conversation, showMeOffered {
            nodes.append(.item(BoardID.showMe))
        }
        let question = conversation.question
        nodes += question.answers.map { ScanNode.item($0.id) }
        nodes += question.strip.map { ScanNode.item($0.id) }
        nodes.append(.item(BoardID.language))
        return nodes
    }
}
