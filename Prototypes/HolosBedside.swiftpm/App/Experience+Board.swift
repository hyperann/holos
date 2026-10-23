import Foundation

/// What the board shows, worked out from where the story is.
///
/// Read-only views of `Experience`'s state, kept apart from the timing
/// code so each file reads as one idea.
@MainActor
extension Experience {
    var currentTurn: NurseTurn? {
        guard step == .conversation, NurseScript.turns.indices.contains(turnIndex) else { return nil }
        return NurseScript.turns[turnIndex]
    }

    /// The one cell the guide marker sits on. When the target lives on the
    /// "Something else" board, the marker leads there one step at a time:
    /// Something else, then the topic, then the word.
    var guideID: String? {
        guard let turn = currentTurn, !conversation.isPartnerTurn, !isShowingHeadTry else { return nil }
        if let topic = MiniTopic.containing(turn.target) {
            if !conversation.isMiniBoardOpen { return Vocabulary.somethingElse.id }
            if conversation.miniTopic != topic { return topic.scanID }
            return turn.target
        }
        return conversation.isMiniBoardOpen ? BoardID.miniClose : turn.target
    }

    /// The banner's second line, following the guide marker. `compact` asks
    /// for the phone version, which has room for two lines.
    func guideDetail(compact: Bool) -> Bilingual? {
        guard let turn = currentTurn else { return nil }
        let detail = compact ? (turn.compactDetail ?? turn.detail) : turn.detail
        guard let guide = guideID else { return detail }
        if MiniTopic(scanID: guide) != nil { return Copy.guideOpenTopic }
        if guide == BoardID.miniClose { return Copy.guideBackToAnswers }
        if conversation.isMiniBoardOpen, guide == turn.target { return Copy.guideChooseCell }
        return detail
    }

    /// The row of the "Something else" board that holds the guide's word.
    /// While scanning, the next press there picks a row, not a word, so the
    /// marker and the banner point at this row until the scan is inside it.
    var guideRowIndex: Int? {
        guard conversation.isMiniBoardOpen, let guide = guideID else { return nil }
        return conversation.miniTopic.rows.firstIndex { row in
            row.contains { $0.id == guide }
        }
    }

    /// Everything the switch can reach right now, in scan order.
    ///
    /// Linear, not row-column: with six answers or fewer, one press per
    /// choice beats two, and there is nothing to hold in mind. Only the
    /// "Something else" board, with eight words, scans by rows. The language
    /// switch is always last, so a switch-only person can reach Ukrainian.
    var scanTree: [ScanNode] {
        guard step == .conversation || step == .free else { return [] }
        guard !conversation.isPartnerTurn, !isShowingHeadTry else { return [] }
        var nodes: [ScanNode] = []
        if step == .conversation, showMeOffered {
            nodes.append(.item(BoardID.showMe))
        }
        if conversation.isMiniBoardOpen {
            for (index, row) in conversation.miniTopic.rows.enumerated() {
                nodes.append(.group(BoardID.miniRow(index), row.map { ScanNode.item($0.id) }))
            }
            nodes += MiniTopic.allCases.map { ScanNode.item($0.scanID) }
            nodes.append(.item(BoardID.miniClose))
        } else {
            let question = conversation.question
            nodes += question.answers.map { ScanNode.item($0.id) }
            nodes += question.strip.map { ScanNode.item($0.id) }
        }
        nodes.append(.item(BoardID.language))
        return nodes
    }
}
