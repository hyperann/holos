import Foundation

/// Every choice on the compass, in both languages.
///
/// Each finished sentence is written out whole, in English and in
/// Ukrainian, rather than glued together from the path. Ukrainian will not
/// be glued: "I need water" is «Мені потрібна вода», but "I need medicine"
/// is «Мені потрібні ліки» — the word for "needed" agrees with the thing
/// needed. A template would get one of them wrong in front of a nurse.
///
/// SF Symbols stand in for pictures here; the real app uses ARASAAC
/// pictograms, which are drawn for exactly this use. The pain choices use
/// the 0–10 numbers that ward staff already ask about.
enum Vocabulary {
    // MARK: - Ids the guided step needs

    static let homeID = "home"
    /// The judged goal: "My head hurts a lot. I need medicine, please."
    static let goalLeafIDs = ["pain.head.alot", "need.medicine"]

    /// The goal's words, for the Ukrainian step when the person skipped
    /// building the message themselves.
    static var goalWords: Bilingual {
        Bilingual.joined(goalLeafIDs.compactMap { tree.choice(id: $0)?.words })
    }

    static let tree = CompassTree(
        home: home,
        levels: [need, needMore, feel, feelMore, pain, painHead, painChest, painStomach, painLeg]
    )

    // MARK: - Home

    /// Yes and No are one press from home, always: they answer most of
    /// what anyone at a bedside will ask.
    static let home = CompassLevel(
        id: homeID,
        draft: Bilingual("Four choices. Pick one.", uk: "Чотири варіанти. Оберіть один."),
        crumb: Bilingual("Start", uk: "Початок"),
        north: CompassChoice("yes", Bilingual("Yes", uk: "Так"), symbol: "hand.thumbsup.fill", kind: .action, .answer(Bilingual("Yes.", uk: "Так."))),
        east: CompassChoice("no", Bilingual("No", uk: "Ні"), symbol: "hand.thumbsdown.fill", kind: .urgent, .answer(Bilingual("No.", uk: "Ні."))),
        south: CompassChoice("need", Bilingual("I need…", uk: "Мені потрібно…"), symbol: "hand.raised.fill", kind: .thing, .open("need")),
        west: CompassChoice("feel", Bilingual("I feel…", uk: "Я почуваюся…"), symbol: "heart.fill", kind: .describing, .open("feel"))
    )

    // MARK: - I need…

    /// The draft says where the path is heading. In English a half
    /// sentence ("I need…") reads on into every choice below it; Ukrainian
    /// would not agree («Мені потрібно… Вода»), so there it is a heading.
    static let need = CompassLevel(
        id: "need",
        draft: Bilingual("I need…", uk: "Що мені потрібно:"),
        crumb: Bilingual("I need", uk: "Мені потрібно"),
        north: CompassChoice(
            "need.water", Bilingual("Water", uk: "Вода"), symbol: "drop.fill", kind: .thing,
            .sentence(Bilingual("I need water, please.", uk: "Мені потрібна вода, будь ласка."))
        ),
        east: CompassChoice(
            "need.medicine", Bilingual("Medicine", uk: "Ліки"), symbol: "pills.fill", kind: .thing,
            .sentence(Bilingual("I need medicine, please.", uk: "Мені потрібні ліки, будь ласка."))
        ),
        south: CompassChoice(
            "need.toilet", Bilingual("Toilet", uk: "Туалет"), symbol: "toilet.fill", kind: .thing,
            .sentence(Bilingual("I need the toilet, please.", uk: "Мені потрібно в туалет, будь ласка."))
        ),
        west: CompassChoice("need.more", Bilingual("More…", uk: "Ще…"), symbol: "square.grid.2x2.fill", kind: .control, .open("need.more"))
    )

    static let needMore = CompassLevel(
        id: "need.more",
        draft: Bilingual("I need…", uk: "Що мені потрібно:"),
        crumb: Bilingual("More", uk: "Ще"),
        north: CompassChoice(
            "need.nurse", Bilingual("Nurse", uk: "Медсестра"), symbol: "stethoscope", kind: .people,
            .sentence(Bilingual("Please call the nurse.", uk: "Покличте, будь ласка, медсестру."))
        ),
        east: CompassChoice(
            "need.move", Bilingual("Help moving", uk: "Змінити положення"), symbol: "figure.roll", kind: .action,
            .sentence(Bilingual("Please help me change position.", uk: "Допоможіть мені, будь ласка, змінити положення."))
        ),
        south: CompassChoice(
            "need.rest", Bilingual("Rest", uk: "Відпочити"), symbol: "bed.double.fill", kind: .action,
            .sentence(Bilingual("I need to rest now.", uk: "Мені потрібно відпочити."))
        ),
        west: CompassChoice(
            "need.home", Bilingual("To go home", uk: "Додому"), symbol: "house.fill", kind: .action,
            .sentence(Bilingual("I want to go home.", uk: "Я хочу додому."))
        )
    )

    // MARK: - I feel…

    static let feel = CompassLevel(
        id: "feel",
        draft: Bilingual("I feel…", uk: "Як я почуваюся:"),
        crumb: Bilingual("I feel", uk: "Я почуваюся"),
        north: CompassChoice("feel.pain", Bilingual("Pain…", uk: "Біль…"), symbol: "bandage.fill", kind: .urgent, .open("pain")),
        east: CompassChoice(
            "feel.tired", Bilingual("Tired", uk: "Втомився", ukFeminine: "Втомилася"), symbol: "moon.zzz.fill", kind: .describing,
            .sentence(Bilingual("I'm tired.", uk: "Я втомився.", ukFeminine: "Я втомилася."))
        ),
        south: CompassChoice(
            "feel.scared", Bilingual("Scared", uk: "Страшно"), symbol: "face.dashed", kind: .describing,
            .sentence(Bilingual("I'm scared.", uk: "Мені страшно."))
        ),
        west: CompassChoice("feel.more", Bilingual("More…", uk: "Ще…"), symbol: "square.grid.2x2.fill", kind: .control, .open("feel.more"))
    )

    static let feelMore = CompassLevel(
        id: "feel.more",
        draft: Bilingual("I feel…", uk: "Як я почуваюся:"),
        crumb: Bilingual("More", uk: "Ще"),
        north: CompassChoice(
            "feel.hot", Bilingual("Too hot", uk: "Жарко"), symbol: "thermometer.sun.fill", kind: .describing,
            .sentence(Bilingual("I'm too hot.", uk: "Мені жарко."))
        ),
        east: CompassChoice(
            "feel.cold", Bilingual("Too cold", uk: "Холодно"), symbol: "thermometer.snowflake", kind: .describing,
            .sentence(Bilingual("I'm too cold.", uk: "Мені холодно."))
        ),
        south: CompassChoice(
            "feel.unwell", Bilingual("Unwell", uk: "Погано"), symbol: "thermometer.medium", kind: .describing,
            .sentence(Bilingual("I feel unwell.", uk: "Мені погано."))
        ),
        west: CompassChoice(
            "feel.better", Bilingual("Better", uk: "Краще"), symbol: "sun.max.fill", kind: .describing,
            .sentence(Bilingual("I feel better.", uk: "Мені краще."))
        )
    )

    // MARK: - Pain

    static let pain = CompassLevel(
        id: "pain",
        draft: Bilingual("It hurts…", uk: "Де болить:"),
        crumb: Bilingual("Pain", uk: "Біль"),
        north: CompassChoice("pain.head", Bilingual("Head", uk: "Голова"), symbol: "brain.head.profile", kind: .thing, .open("pain.head")),
        east: CompassChoice("pain.chest", Bilingual("Chest", uk: "Груди"), symbol: "lungs.fill", kind: .thing, .open("pain.chest")),
        south: CompassChoice("pain.stomach", Bilingual("Stomach", uk: "Живіт"), symbol: "figure.stand", kind: .thing, .open("pain.stomach")),
        west: CompassChoice("pain.leg", Bilingual("Leg", uk: "Нога"), symbol: "shoeprints.fill", kind: .thing, .open("pain.leg"))
    )

    /// "How much?" — the same four steps for every part of the body, each
    /// sentence written out in full (see the type comment).
    static let painHead = howMuch(
        part: "head",
        draft: Bilingual("My head hurts…", uk: "Болить голова…"),
        crumb: Bilingual("Head", uk: "Голова"),
        little: Bilingual("My head hurts a little.", uk: "Трохи болить голова."),
        medium: Bilingual("My head hurts moderately.", uk: "Помірно болить голова."),
        alot: Bilingual("My head hurts a lot.", uk: "Дуже болить голова."),
        worst: Bilingual("My head hurts unbearably.", uk: "Нестерпно болить голова.")
    )

    static let painChest = howMuch(
        part: "chest",
        draft: Bilingual("My chest hurts…", uk: "Болить у грудях…"),
        crumb: Bilingual("Chest", uk: "Груди"),
        little: Bilingual("My chest hurts a little.", uk: "Трохи болить у грудях."),
        medium: Bilingual("My chest hurts moderately.", uk: "Помірно болить у грудях."),
        alot: Bilingual("My chest hurts a lot.", uk: "Дуже болить у грудях."),
        worst: Bilingual("My chest hurts unbearably.", uk: "Нестерпно болить у грудях.")
    )

    static let painStomach = howMuch(
        part: "stomach",
        draft: Bilingual("My stomach hurts…", uk: "Болить живіт…"),
        crumb: Bilingual("Stomach", uk: "Живіт"),
        little: Bilingual("My stomach hurts a little.", uk: "Трохи болить живіт."),
        medium: Bilingual("My stomach hurts moderately.", uk: "Помірно болить живіт."),
        alot: Bilingual("My stomach hurts a lot.", uk: "Дуже болить живіт."),
        worst: Bilingual("My stomach hurts unbearably.", uk: "Нестерпно болить живіт.")
    )

    static let painLeg = howMuch(
        part: "leg",
        draft: Bilingual("My leg hurts…", uk: "Болить нога…"),
        crumb: Bilingual("Leg", uk: "Нога"),
        little: Bilingual("My leg hurts a little.", uk: "Трохи болить нога."),
        medium: Bilingual("My leg hurts moderately.", uk: "Помірно болить нога."),
        alot: Bilingual("My leg hurts a lot.", uk: "Дуже болить нога."),
        worst: Bilingual("My leg hurts unbearably.", uk: "Нестерпно болить нога.")
    )

    private static func howMuch(
        part: String,
        draft: Bilingual,
        crumb: Bilingual,
        little: Bilingual,
        medium: Bilingual,
        alot: Bilingual,
        worst: Bilingual
    ) -> CompassLevel {
        let id = "pain.\(part)"
        return CompassLevel(
            id: id,
            draft: draft,
            crumb: crumb,
            north: CompassChoice("\(id).little", Bilingual("A little", uk: "Трохи"), symbol: "2.circle.fill", kind: .describing, .sentence(little)),
            east: CompassChoice("\(id).medium", Bilingual("Medium", uk: "Помірно"), symbol: "5.circle.fill", kind: .describing, .sentence(medium)),
            south: CompassChoice("\(id).alot", Bilingual("A lot", uk: "Дуже"), symbol: "8.circle.fill", kind: .urgent, .sentence(alot)),
            west: CompassChoice("\(id).worst", Bilingual("Unbearable", uk: "Нестерпно"), symbol: "10.circle.fill", kind: .urgent, .sentence(worst))
        )
    }
}
