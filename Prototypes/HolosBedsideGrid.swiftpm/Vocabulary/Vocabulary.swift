/// Every answer the conversation can offer.
///
/// Labels are short so they can be recognised at a glance; what is SPOKEN
/// is a whole, polite sentence, because the listener should hear an adult
/// talking, not a list of nouns. Ukrainian forms that change with the
/// speaker's gender carry `ukFeminine` ("Я втомився" / "Я втомилася").
///
/// SF Symbols stand in for pictures here; the real app swaps in ARASAAC
/// pictograms, which are drawn for exactly this use. The whole board's
/// cells live in `BoardVocabulary`.
enum Vocabulary {
    // MARK: - Answers by question

    static func answers(for question: Question) -> [Phrase] {
        switch question {
        case .feeling: feeling
        case .painWhere: body
        case .painHowBad: scale
        case .needs: needs
        case .whoToCall: call
        case .rest: rest
        case .anythingElse: tell
        }
    }

    /// "In pain" leads: the answer that matters most is lit first.
    static let feeling: [Phrase] = [
        Phrase("feel.pain", Bilingual("In pain", uk: "Болить"),
               says: Bilingual("I'm in pain.", uk: "Мені боляче."),
               symbol: "bandage.fill", kind: .urgent),
        Phrase("feel.tired", Bilingual("Tired", uk: "Втомився", ukFeminine: "Втомилася"),
               says: Bilingual("I'm tired.", uk: "Я втомився.", ukFeminine: "Я втомилася."),
               symbol: "moon.zzz.fill", kind: .describing),
        Phrase("feel.good", Bilingual("Good", uk: "Добре"),
               says: Bilingual("I feel good.", uk: "Я почуваюся добре."),
               symbol: "face.smiling", kind: .describing),
        Phrase("feel.notGood", Bilingual("Not good", uk: "Погано"),
               says: Bilingual("I don't feel well.", uk: "Мені погано."),
               symbol: "cloud.rain.fill", kind: .describing),
        Phrase("feel.scared", Bilingual("Scared", uk: "Страшно"),
               says: Bilingual("I'm scared.", uk: "Мені страшно."),
               symbol: "exclamationmark.triangle.fill", kind: .describing),
    ]

    /// In the same order as `BodyRegion`, head first.
    static let body: [Phrase] = [
        Phrase("body.head", Bilingual("Head", uk: "Голова"),
               says: Bilingual("My head hurts.", uk: "Болить голова."),
               symbol: "brain.head.profile", kind: .thing),
        Phrase("body.chest", Bilingual("Chest", uk: "Груди"),
               says: Bilingual("My chest hurts.", uk: "Болить у грудях."),
               symbol: "lungs.fill", kind: .thing),
        Phrase("body.stomach", Bilingual("Stomach", uk: "Живіт"),
               says: Bilingual("My stomach hurts.", uk: "Болить живіт."),
               symbol: "figure.stand", kind: .thing),
        Phrase("body.back", Bilingual("Back", uk: "Спина"),
               says: Bilingual("My back hurts.", uk: "Болить спина."),
               symbol: "figure.walk", kind: .thing),
        Phrase("body.arm", Bilingual("Arm", uk: "Рука"),
               says: Bilingual("My arm hurts.", uk: "Болить рука."),
               symbol: "hand.raised.fill", kind: .thing),
        Phrase("body.leg", Bilingual("Leg", uk: "Нога"),
               says: Bilingual("My leg hurts.", uk: "Болить нога."),
               symbol: "shoeprints.fill", kind: .thing),
    ]

    /// A scale must stay in order, so the likely answer is not moved up:
    /// reordering a scale would make it lie.
    ///
    /// No numbers anywhere: the person chose a word and a face, not a 0–10
    /// score, and a "7" in the transcript could be written down as one.
    /// The cells and the person's bubbles draw the face (`PainFace`); the
    /// symbol is only a number-free stand-in for anywhere else.
    static let scale: [Phrase] = [
        Phrase("scale.little", Bilingual("A little", uk: "Трохи"),
               says: Bilingual("A little.", uk: "Трохи."),
               symbol: "thermometer.medium", kind: .describing),
        Phrase("scale.medium", Bilingual("Medium", uk: "Помірно"),
               says: Bilingual("Medium.", uk: "Помірно."),
               symbol: "thermometer.medium", kind: .describing),
        Phrase("scale.lot", Bilingual("A lot", uk: "Сильно"),
               says: Bilingual("A lot.", uk: "Сильно."),
               symbol: "thermometer.medium", kind: .describing),
        Phrase("scale.worst", Bilingual("The worst ever", uk: "Нестерпно"),
               says: Bilingual("It's the worst pain ever.", uk: "Нестерпно."),
               symbol: "thermometer.medium", kind: .urgent),
    ]

    static let needs: [Phrase] = [
        Phrase("need.water", Bilingual("Water", uk: "Вода"),
               says: Bilingual("Water, please.", uk: "Води, будь ласка."),
               symbol: "drop.fill", kind: .thing),
        Phrase("need.medicine", Bilingual("Medicine", uk: "Ліки"),
               says: Bilingual("Medicine, please.", uk: "Ліки, будь ласка."),
               symbol: "pills.fill", kind: .thing),
        Phrase("need.toilet", Bilingual("Toilet", uk: "Туалет"),
               says: Bilingual("I need the toilet.", uk: "Мені треба в туалет."),
               symbol: "toilet.fill", kind: .thing),
        Phrase("need.move", Bilingual("Help me move", uk: "Змінити позу"),
               says: Bilingual("Please help me change position.", uk: "Допоможіть мені, будь ласка, змінити позу."),
               symbol: "bed.double.fill", kind: .action),
        Phrase("need.rest", Bilingual("Rest", uk: "Відпочити"),
               says: Bilingual("I'd like to rest.", uk: "Я хочу відпочити."),
               symbol: "moon.fill", kind: .action),
        Phrase("need.nothing", Bilingual("Nothing, thanks", uk: "Нічого, дякую"),
               says: Bilingual("Nothing, thank you.", uk: "Нічого, дякую."),
               symbol: "checkmark.circle.fill", kind: .social),
    ]

    /// Answers to "Who should we call?" — Ukrainian answers in the dative,
    /// the way a person answers «Кому?».
    static let call: [Phrase] = [
        Phrase("call.wife", Bilingual("Wife", uk: "Дружина"),
               says: Bilingual("My wife, please.", uk: "Дружині, будь ласка."),
               symbol: "heart.circle.fill", kind: .people),
        Phrase("call.husband", Bilingual("Husband", uk: "Чоловік"),
               says: Bilingual("My husband, please.", uk: "Чоловікові, будь ласка."),
               symbol: "person.crop.circle.fill", kind: .people),
        Phrase("call.mum", Bilingual("Mum", uk: "Мама"),
               says: Bilingual("My mum, please.", uk: "Мамі, будь ласка."),
               symbol: "figure.and.child.holdinghands", kind: .people),
        Phrase("call.son", Bilingual("Son", uk: "Син"),
               says: Bilingual("My son, please.", uk: "Синові, будь ласка."),
               symbol: "figure.wave", kind: .people),
        Phrase("call.daughter", Bilingual("Daughter", uk: "Донька"),
               says: Bilingual("My daughter, please.", uk: "Доньці, будь ласка."),
               symbol: "person.fill", kind: .people),
        Phrase("call.friend", Bilingual("A friend", uk: "Друг"),
               says: Bilingual("A friend, please.", uk: "Другові, будь ласка."),
               symbol: "person.2.fill", kind: .people),
    ]

    static let rest: [Phrase] = [
        Phrase("rest.sleep", Bilingual("Sleep", uk: "Поспати"),
               says: Bilingual("Yes, I'd like to sleep.", uk: "Так, я хочу поспати."),
               symbol: "moon.zzz.fill", kind: .action),
        Phrase("rest.lightOff", Bilingual("Light off", uk: "Вимкнути світло"),
               says: Bilingual("Please turn off the light.", uk: "Вимкніть, будь ласка, світло."),
               symbol: "lightbulb.fill", kind: .action),
        Phrase("rest.quiet", Bilingual("Quiet", uk: "Тиша"),
               says: Bilingual("Some quiet, please.", uk: "Тихіше, будь ласка."),
               symbol: "speaker.slash.fill", kind: .thing),
        Phrase("rest.sitUp", Bilingual("Sit up", uk: "Сісти"),
               says: Bilingual("I'd like to sit up.", uk: "Я хочу сісти."),
               symbol: "chair.fill", kind: .action),
        Phrase("rest.notNow", Bilingual("Not now", uk: "Не зараз"),
               says: Bilingual("Not now, thank you.", uk: "Не зараз, дякую."),
               symbol: "clock.fill", kind: .social),
    ]

    /// An open question cannot be predicted, so "Something else" leads.
    static let tell: [Phrase] = [
        Vocabulary.somethingElse,
        Phrase("tell.thanks", Bilingual("Thank you", uk: "Дякую"),
               says: Bilingual("Thank you.", uk: "Дякую."),
               symbol: "heart.fill", kind: .social),
        Phrase("tell.ok", Bilingual("I'm OK", uk: "Усе гаразд"),
               says: Bilingual("I'm OK.", uk: "Усе гаразд."),
               symbol: "sun.max.fill", kind: .social),
        Phrase("tell.home", Bilingual("Home", uk: "Додому"),
               says: Bilingual("I want to go home.", uk: "Я хочу додому."),
               symbol: "house.fill", kind: .thing),
        Phrase("tell.later", Bilingual("Talk later", uk: "Поговорити пізніше"),
               says: Bilingual("Can we talk later?", uk: "Можна поговорити пізніше?"),
               symbol: "clock.fill", kind: .social),
    ]

    // MARK: - The strip under every question

    /// Opens the whole board. It never speaks, so its `says` is unused.
    static let somethingElse = Phrase(
        "somethingElse", Bilingual("Something else", uk: "Щось інше"),
        symbol: "ellipsis.bubble.fill", kind: .control
    )

    static let strip: [Phrase] = [
        Phrase("yes", Bilingual("Yes", uk: "Так"),
               says: Bilingual("Yes.", uk: "Так."),
               symbol: "hand.thumbsup.fill", kind: .action),
        Phrase("no", Bilingual("No", uk: "Ні"),
               says: Bilingual("No.", uk: "Ні."),
               symbol: "hand.thumbsdown.fill", kind: .urgent),
        Phrase("notSure", Bilingual("Not sure", uk: "Не впевнений", ukFeminine: "Не впевнена"),
               says: Bilingual("I'm not sure.", uk: "Я не впевнений.", ukFeminine: "Я не впевнена."),
               symbol: "questionmark.circle.fill", kind: .question),
        Vocabulary.somethingElse,
    ]

    // MARK: - Lookup

    /// Every phrase once, for finding one by the id the scanner reports.
    static let all: [Phrase] = {
        let groups: [[Phrase]] = [
            Vocabulary.feeling, Vocabulary.body, Vocabulary.scale, Vocabulary.needs,
            Vocabulary.call, Vocabulary.rest, Vocabulary.tell, Vocabulary.strip,
        ]
        return groups.flatMap { $0 }
    }()

    // "Something else" sits in two lists; the first copy wins, and both
    // copies are the same phrase anyway.
    private static let byID: [String: Phrase] = Dictionary(
        Vocabulary.all.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static func phrase(id: String) -> Phrase? {
        byID[id]
    }
}
