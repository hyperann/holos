/// One exchange in the guided story: the nurse asks, the person answers,
/// the nurse responds.
///
/// The script branches only as far as kindness needs. The expected answer
/// gets a reply that fits it; ANY other answer gets a warm, generic one and
/// the story carries on. A judge who picks "Scared" instead of "In pain"
/// is never told they were wrong — real conversations do not have wrong
/// answers either.
struct NurseTurn: Sendable {
    /// Which judged step this exchange belongs to.
    enum Stage: Sendable {
        /// Step 2: one switch, a whole conversation.
        case voice
        /// Step 3: when the word won't come.
        case aphasia
    }

    let stage: Stage
    /// A stage direction shown before the question, if time has passed.
    let note: Bilingual?
    /// The nurse's question.
    let asks: Bilingual
    /// The question's wording after an answer the plain one does not fit,
    /// so the nurse never pretends she heard something she did not.
    let asksIfSurprised: Bilingual?
    /// The previous answers after which the plain `asks` still fits. `nil`
    /// means just the previous turn's target. Decided by what was actually
    /// said: "How bad is it?" fits after ANY place on the body, not only
    /// after the head.
    let plainAfter: Set<String>?
    /// Which answers the board offers.
    let question: Question
    /// The answer the guide marker leads to. It may live on the
    /// "Something else" board; the marker then leads there step by step.
    let target: String
    let goal: Bilingual
    let detail: Bilingual?
    /// A shorter detail for a phone, whose banner has room for two lines.
    let compactDetail: Bilingual?
    let replyToTarget: [Bilingual]
    let replyToOther: [Bilingual]

    init(
        stage: Stage,
        note: Bilingual? = nil,
        asks: Bilingual,
        asksIfSurprised: Bilingual? = nil,
        plainAfter: Set<String>? = nil,
        question: Question,
        target: String,
        goal: Bilingual,
        detail: Bilingual? = nil,
        compactDetail: Bilingual? = nil,
        replyToTarget: [Bilingual],
        replyToOther: [Bilingual]
    ) {
        self.stage = stage
        self.note = note
        self.asks = asks
        self.asksIfSurprised = asksIfSurprised
        self.plainAfter = plainAfter
        self.question = question
        self.target = target
        self.goal = goal
        self.detail = detail
        self.compactDetail = compactDetail
        self.replyToTarget = replyToTarget
        self.replyToOther = replyToOther
    }

    var stepLabel: Bilingual {
        switch stage {
        case .voice: Copy.step2
        case .aphasia: Copy.step3
        }
    }
}

/// The nurse's side of the guided story.
///
/// Four quick exchanges build "I'm in pain. My head hurts. A lot. Water,
/// please." — each with a different kind of board — and a fifth reaches
/// past the prediction for a word the person cannot recall.
enum NurseScript {
    static let turns: [NurseTurn] = [
        NurseTurn(
            stage: .voice,
            note: Copy.noteTenMinutes,
            asks: Copy.nurseBack,
            question: .feeling,
            target: "feel.pain",
            goal: Copy.goalPain,
            detail: Copy.goalPainDetail,
            replyToTarget: [Copy.nurseSorry],
            replyToOther: [Copy.nurseThanksForTelling]
        ),
        NurseTurn(
            stage: .voice,
            asks: Copy.nurseWhereHurts,
            asksIfSurprised: Copy.nurseAnythingHurt,
            question: .painWhere,
            target: "body.head",
            goal: Copy.goalHead,
            detail: Copy.goalHeadDetail,
            replyToTarget: [Copy.nurseYourHead],
            replyToOther: [Copy.nurseThanks]
        ),
        NurseTurn(
            stage: .voice,
            asks: Copy.nurseHowBad,
            asksIfSurprised: Copy.nurseHowBadIfAny,
            plainAfter: Set(Vocabulary.body.map(\.id)),
            question: .painHowBad,
            target: "scale.lot",
            goal: Copy.goalALot,
            detail: Copy.goalALotDetail,
            replyToTarget: [Copy.nurseMedicine],
            replyToOther: [Copy.nurseWillTellDoctor]
        ),
        NurseTurn(
            stage: .voice,
            asks: Copy.nurseAnythingElse,
            question: .needs,
            target: "need.water",
            goal: Copy.goalWater,
            replyToTarget: [Copy.nurseComingUp],
            replyToOther: [Copy.nurseThanksAllRight]
        ),
        NurseTurn(
            stage: .aphasia,
            note: Copy.noteLittleLater,
            asks: Copy.nurseTellMe,
            question: .anythingElse,
            target: "talk.wife",
            goal: Copy.goalWife,
            detail: Copy.goalWifeDetail,
            compactDetail: Copy.goalWifeDetailShort,
            replyToTarget: [Copy.nurseCallWife],
            replyToOther: [Copy.nurseHearYou]
        ),
    ]
}
