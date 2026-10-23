/// The six adult topic boards of the whole board, in the order they sit in
/// the topics row.
///
/// This is Holos Grid's vocabulary, unchanged except for plain English
/// apostrophes (Bedside's convention). Topics, not one giant page, because
/// aphasia makes searching costly: ten things that belong together are one
/// glance; sixty unrelated things are a test. Each topic is exactly two rows
/// of five, so the grid never moves under the person — only the words change.
enum Topic: String, CaseIterable, Identifiable, Sendable {
    case needs
    case pain
    case medicine
    case family
    case feelings
    case talk

    var id: String { rawValue }

    var name: Bilingual {
        switch self {
        case .needs: Copy.topicNeeds
        case .pain: Copy.topicPain
        case .medicine: Copy.topicMedicine
        case .family: Copy.topicFamily
        case .feelings: Copy.topicFeelings
        case .talk: Copy.topicTalk
        }
    }

    var symbol: String {
        switch self {
        case .needs: "cup.and.saucer.fill"
        case .pain: "bandage.fill"
        case .medicine: "pills.fill"
        case .family: "person.3.fill"
        case .feelings: "face.smiling"
        case .talk: "bubble.left.and.bubble.right.fill"
        }
    }

    var phrases: [Phrase] {
        switch self {
        case .needs: BoardVocabulary.needs
        case .pain: BoardVocabulary.pain
        case .medicine: BoardVocabulary.medicine
        case .family: BoardVocabulary.family
        case .feelings: BoardVocabulary.feelings
        case .talk: BoardVocabulary.talk
        }
    }

    /// The id this topic's tab has in the scan.
    var scanID: String { "topic." + rawValue }

    init?(scanID: String) {
        guard scanID.hasPrefix("topic.") else { return nil }
        self.init(rawValue: String(scanID.dropFirst("topic.".count)))
    }

    /// The topic holding a cell, if it is on the whole board at all.
    static func containing(_ phraseID: String) -> Topic? {
        allCases.first { topic in topic.phrases.contains { $0.id == phraseID } }
    }
}

/// Every cell on the whole board.
///
/// Labels are one to three words, recognisable at a glance; what a cell says
/// is a whole polite sentence, so the person never sounds more abrupt than
/// they are. Ukrainian forms that change with the speaker's gender carry
/// `ukFeminine` ("Я втомився" / "Я втомилася").
///
/// The SF Symbols are placeholders. The real app uses ARASAAC pictograms; a
/// few placeholders here (stomach, back) are only approximate because SF
/// Symbols has no anatomy set.
enum BoardVocabulary {
    // MARK: - Quick phrases

    /// Spoken the moment they are chosen, never added to a message: "Help"
    /// cannot wait for a sentence to be built. Each one is the person's
    /// whole turn in the conversation.
    static let quick: [Phrase] = [
        Phrase("quick.help", Bilingual("Help", uk: "Допоможіть"),
               says: Bilingual("Help me, please!", uk: "Допоможіть, будь ласка!"),
               symbol: "exclamationmark.triangle.fill", kind: .urgent),
        Phrase("quick.yes", Bilingual("Yes", uk: "Так"),
               says: Bilingual("Yes.", uk: "Так."),
               symbol: "hand.thumbsup.fill", kind: .urgent),
        Phrase("quick.no", Bilingual("No", uk: "Ні"),
               says: Bilingual("No.", uk: "Ні."),
               symbol: "hand.thumbsdown.fill", kind: .urgent),
        Phrase("quick.pain", Bilingual("I'm in pain", uk: "Мені боляче"),
               says: Bilingual("I'm in pain.", uk: "Мені боляче."),
               symbol: "bandage.fill", kind: .urgent),
        Phrase("quick.wait", Bilingual("Wait, please", uk: "Зачекайте"),
               says: Bilingual("Wait, please. I need a moment.", uk: "Зачекайте, будь ласка. Мені потрібна хвилинка."),
               symbol: "hourglass", kind: .urgent),
    ]

    // MARK: - Topics

    static let needs: [Phrase] = [
        Phrase("needs.water", Bilingual("Water", uk: "Вода"),
               says: Bilingual("Water, please.", uk: "Води, будь ласка."),
               symbol: "drop.fill", kind: .thing),
        Phrase("needs.food", Bilingual("Food", uk: "Їжа"),
               says: Bilingual("I'd like something to eat.", uk: "Я хочу їсти."),
               symbol: "fork.knife", kind: .thing),
        Phrase("needs.toilet", Bilingual("Toilet", uk: "Туалет"),
               says: Bilingual("I need the toilet.", uk: "Мені треба в туалет."),
               symbol: "toilet.fill", kind: .thing),
        Phrase("needs.wash", Bilingual("Wash", uk: "Помитися"),
               says: Bilingual("I'd like to wash.", uk: "Я хочу помитися."),
               symbol: "shower.fill", kind: .action),
        Phrase("needs.rest", Bilingual("Rest", uk: "Відпочити"),
               says: Bilingual("I'd like to rest.", uk: "Я хочу відпочити."),
               symbol: "moon.zzz.fill", kind: .action),
        Phrase("needs.sitUp", Bilingual("Sit up", uk: "Сісти"),
               says: Bilingual("Please help me sit up.", uk: "Допоможіть мені сісти, будь ласка."),
               symbol: "chair.fill", kind: .action),
        Phrase("needs.lieDown", Bilingual("Lie down", uk: "Лягти"),
               says: Bilingual("Please help me lie down.", uk: "Допоможіть мені лягти, будь ласка."),
               symbol: "bed.double.fill", kind: .action),
        Phrase("needs.hot", Bilingual("Too hot", uk: "Жарко"),
               says: Bilingual("I'm too hot.", uk: "Мені жарко."),
               symbol: "thermometer.sun.fill", kind: .describing),
        Phrase("needs.cold", Bilingual("Too cold", uk: "Холодно"),
               says: Bilingual("I'm too cold.", uk: "Мені холодно."),
               symbol: "thermometer.snowflake", kind: .describing),
        Phrase("needs.glasses", Bilingual("My glasses", uk: "Окуляри"),
               says: Bilingual("My glasses, please.", uk: "Подайте, будь ласка, мої окуляри."),
               symbol: "eyeglasses", kind: .thing),
    ]

    /// "I'm in pain" comes first: the commonest message in a ward is one
    /// press into the first topic row.
    static let pain: [Phrase] = [
        Phrase("pain.inPain", Bilingual("I'm in pain", uk: "Мені боляче"),
               says: Bilingual("I'm in pain.", uk: "Мені боляче."),
               symbol: "bandage.fill", kind: .urgent),
        Phrase("pain.head", Bilingual("Head", uk: "Голова"),
               says: Bilingual("My head hurts.", uk: "Болить голова."),
               symbol: "brain.head.profile", kind: .thing),
        Phrase("pain.chest", Bilingual("Chest", uk: "Груди"),
               says: Bilingual("My chest hurts.", uk: "Болить у грудях."),
               symbol: "heart.fill", kind: .thing),
        Phrase("pain.stomach", Bilingual("Stomach", uk: "Живіт"),
               says: Bilingual("My stomach hurts.", uk: "Болить живіт."),
               symbol: "figure.stand", kind: .thing),
        Phrase("pain.back", Bilingual("Back", uk: "Спина"),
               says: Bilingual("My back hurts.", uk: "Болить спина."),
               symbol: "figure.walk", kind: .thing),
        Phrase("pain.arm", Bilingual("Arm", uk: "Рука"),
               says: Bilingual("My arm hurts.", uk: "Болить рука."),
               symbol: "hand.raised.fill", kind: .thing),
        Phrase("pain.leg", Bilingual("Leg", uk: "Нога"),
               says: Bilingual("My leg hurts.", uk: "Болить нога."),
               symbol: "shoeprints.fill", kind: .thing),
        Phrase("pain.throat", Bilingual("Throat", uk: "Горло"),
               says: Bilingual("My throat hurts.", uk: "Болить горло."),
               symbol: "mouth.fill", kind: .thing),
        // The numbers echo the 0–10 pain scale nurses already ask about.
        Phrase("pain.little", Bilingual("A little", uk: "Трохи"),
               says: Bilingual("A little.", uk: "Трохи."),
               symbol: "3.circle.fill", kind: .describing),
        Phrase("pain.lot", Bilingual("A lot", uk: "Дуже"),
               says: Bilingual("A lot.", uk: "Дуже сильно."),
               symbol: "8.circle.fill", kind: .describing),
    ]

    static let medicine: [Phrase] = [
        Phrase("medicine.medicine", Bilingual("Medicine", uk: "Ліки"),
               says: Bilingual("Medicine, please.", uk: "Ліки, будь ласка."),
               symbol: "pills.fill", kind: .thing),
        Phrase("medicine.nurse", Bilingual("Nurse", uk: "Медсестра"),
               says: Bilingual("Please call the nurse.", uk: "Покличте, будь ласка, медсестру."),
               symbol: "cross.case.fill", kind: .people),
        Phrase("medicine.doctor", Bilingual("Doctor", uk: "Лікар"),
               says: Bilingual("Please call the doctor.", uk: "Покличте, будь ласка, лікаря."),
               symbol: "stethoscope", kind: .people),
        Phrase("medicine.notHelping", Bilingual("It doesn't help", uk: "Не допомагає"),
               says: Bilingual("It doesn't help.", uk: "Це не допомагає."),
               symbol: "xmark.circle.fill", kind: .describing),
        Phrase("medicine.sick", Bilingual("I feel sick", uk: "Нудить"),
               says: Bilingual("I feel sick.", uk: "Мене нудить."),
               symbol: "face.dashed", kind: .describing),
        Phrase("medicine.dizzy", Bilingual("Dizzy", uk: "Паморочиться"),
               says: Bilingual("I feel dizzy.", uk: "У мене паморочиться в голові."),
               symbol: "sparkles", kind: .describing),
        Phrase("medicine.breathe", Bilingual("Hard to breathe", uk: "Важко дихати"),
               says: Bilingual("It's hard to breathe.", uk: "Мені важко дихати."),
               symbol: "lungs.fill", kind: .urgent),
        Phrase("medicine.itchy", Bilingual("Itchy", uk: "Свербить"),
               says: Bilingual("It's itchy.", uk: "У мене свербить."),
               symbol: "hand.point.up.left.fill", kind: .describing),
        Phrase("medicine.when", Bilingual("When?", uk: "Коли?"),
               says: Bilingual("When?", uk: "Коли?"),
               symbol: "calendar", kind: .question),
        Phrase("medicine.allergic", Bilingual("I'm allergic", uk: "У мене алергія"),
               says: Bilingual("I'm allergic.", uk: "У мене алергія."),
               symbol: "allergens", kind: .urgent),
    ]

    /// One recognised word, one whole sentence: this is the cell step 3 is about.
    static let wife = Phrase(
        "family.wife",
        Bilingual("Wife", uk: "Дружина"),
        says: Bilingual("Please call my wife.", uk: "Подзвоніть, будь ласка, моїй дружині."),
        symbol: "heart.circle.fill", kind: .people
    )

    /// In a ward, naming a family member almost always means "reach them",
    /// so each cell says the whole request. Ukrainian needs the dative here
    /// (моїй дружині, моєму синові) — exactly the kind of ending aphasia
    /// takes away, and exactly why the cell carries the sentence.
    static let family: [Phrase] = [
        wife,
        Phrase("family.husband", Bilingual("Husband", uk: "Чоловік"),
               says: Bilingual("Please call my husband.", uk: "Подзвоніть, будь ласка, моєму чоловікові."),
               symbol: "person.fill", kind: .people),
        Phrase("family.mum", Bilingual("Mum", uk: "Мама"),
               says: Bilingual("Please call my mum.", uk: "Подзвоніть, будь ласка, моїй мамі."),
               symbol: "figure.arms.open", kind: .people),
        Phrase("family.dad", Bilingual("Dad", uk: "Тато"),
               says: Bilingual("Please call my dad.", uk: "Подзвоніть, будь ласка, моєму татові."),
               symbol: "person.crop.circle.fill", kind: .people),
        Phrase("family.son", Bilingual("Son", uk: "Син"),
               says: Bilingual("Please call my son.", uk: "Подзвоніть, будь ласка, моєму синові."),
               symbol: "figure.and.child.holdinghands", kind: .people),
        Phrase("family.daughter", Bilingual("Daughter", uk: "Донька"),
               says: Bilingual("Please call my daughter.", uk: "Подзвоніть, будь ласка, моїй доньці."),
               symbol: "person.wave.2.fill", kind: .people),
        Phrase("family.brother", Bilingual("Brother", uk: "Брат"),
               says: Bilingual("Please call my brother.", uk: "Подзвоніть, будь ласка, моєму братові."),
               symbol: "person.2.fill", kind: .people),
        Phrase("family.sister", Bilingual("Sister", uk: "Сестра"),
               says: Bilingual("Please call my sister.", uk: "Подзвоніть, будь ласка, моїй сестрі."),
               symbol: "figure.wave", kind: .people),
        Phrase("family.friend", Bilingual("Friend", uk: "Друг"),
               says: Bilingual("Please call my friend.", uk: "Подзвоніть, будь ласка, моєму другові."),
               symbol: "face.smiling.inverse", kind: .people),
        Phrase("family.call", Bilingual("Call", uk: "Подзвонити"),
               says: Bilingual("Could I make a phone call?", uk: "Можна мені зателефонувати?"),
               symbol: "phone.fill", kind: .action),
    ]

    static let feelings: [Phrase] = [
        Phrase("feelings.good", Bilingual("Good", uk: "Добре"),
               says: Bilingual("I feel good.", uk: "Я почуваюся добре."),
               symbol: "face.smiling", kind: .describing),
        Phrase("feelings.tired", Bilingual("Tired", uk: "Втомився", ukFeminine: "Втомилася"),
               says: Bilingual("I'm tired.", uk: "Я втомився.", ukFeminine: "Я втомилася."),
               symbol: "zzz", kind: .describing),
        Phrase("feelings.scared", Bilingual("Scared", uk: "Страшно"),
               says: Bilingual("I'm scared.", uk: "Мені страшно."),
               symbol: "bolt.fill", kind: .describing),
        Phrase("feelings.sad", Bilingual("Sad", uk: "Сумно"),
               says: Bilingual("I feel sad.", uk: "Мені сумно."),
               symbol: "cloud.rain.fill", kind: .describing),
        Phrase("feelings.angry", Bilingual("Angry", uk: "Сердитий", ukFeminine: "Сердита"),
               says: Bilingual("I'm angry.", uk: "Я сердитий.", ukFeminine: "Я сердита."),
               symbol: "flame.fill", kind: .describing),
        Phrase("feelings.bored", Bilingual("Bored", uk: "Нудно"),
               says: Bilingual("I'm bored.", uk: "Мені нудно."),
               symbol: "tv.fill", kind: .describing),
        Phrase("feelings.lonely", Bilingual("Lonely", uk: "Самотньо"),
               says: Bilingual("I feel lonely.", uk: "Мені самотньо."),
               symbol: "heart.slash.fill", kind: .describing),
        // Frustration deserves its own cell: being unable to say a word you
        // know is one of the hardest parts of aphasia.
        Phrase("feelings.frustrated", Bilingual("Frustrated", uk: "Роздратований", ukFeminine: "Роздратована"),
               says: Bilingual("I'm frustrated.", uk: "Я роздратований.", ukFeminine: "Я роздратована."),
               symbol: "cloud.fill", kind: .describing),
        Phrase("feelings.better", Bilingual("Better", uk: "Краще"),
               says: Bilingual("I feel better.", uk: "Мені краще."),
               symbol: "arrow.up", kind: .describing),
        Phrase("feelings.worse", Bilingual("Worse", uk: "Гірше"),
               says: Bilingual("I feel worse.", uk: "Мені гірше."),
               symbol: "arrow.down", kind: .describing),
    ]

    /// The conversation repairs aphasia needs most — "slower", "again",
    /// "give me a moment" — come first.
    static let talk: [Phrase] = [
        Phrase("talk.slowly", Bilingual("Speak slowly", uk: "Повільніше"),
               says: Bilingual("Please speak slowly.", uk: "Говоріть, будь ласка, повільніше."),
               symbol: "tortoise.fill", kind: .social),
        Phrase("talk.moment", Bilingual("I need a moment", uk: "Хвилинку"),
               says: Bilingual("I need a moment.", uk: "Мені потрібна хвилинка."),
               symbol: "hourglass", kind: .social),
        Phrase("talk.understand", Bilingual("I understand", uk: "Розумію"),
               says: Bilingual("I understand.", uk: "Я розумію."),
               symbol: "checkmark.circle.fill", kind: .social),
        Phrase("talk.dontUnderstand", Bilingual("I don't understand", uk: "Не розумію"),
               says: Bilingual("I don't understand.", uk: "Я не розумію."),
               symbol: "questionmark.circle.fill", kind: .social),
        Phrase("talk.again", Bilingual("Say it again", uk: "Повторіть"),
               says: Bilingual("Please say it again.", uk: "Повторіть, будь ласка."),
               symbol: "repeat", kind: .social),
        // A heart, not sparkling hands: the picture is a second way to the
        // word, so it has to mean "thank you", not "clean" or "magic". Chest
        // uses the same glyph, but Pain & body and Talk are never on screen
        // together.
        Phrase("talk.thanks", Bilingual("Thank you", uk: "Дякую"),
               says: Bilingual("Thank you.", uk: "Дякую."),
               symbol: "heart.fill", kind: .social),
        Phrase("talk.hello", Bilingual("Hello", uk: "Добрий день"),
               says: Bilingual("Hello.", uk: "Добрий день."),
               symbol: "hand.wave.fill", kind: .social),
        Phrase("talk.goodbye", Bilingual("Goodbye", uk: "До побачення"),
               says: Bilingual("Goodbye.", uk: "До побачення."),
               symbol: "door.left.hand.open", kind: .social),
        Phrase("talk.time", Bilingual("What time is it?", uk: "Котра година?"),
               says: Bilingual("What time is it?", uk: "Котра година?"),
               symbol: "clock.fill", kind: .question),
        // "Home", not "Go home": the message bar shows labels, and "Go home"
        // on it reads as telling the visitor to leave.
        Phrase("talk.home", Bilingual("Home", uk: "Додому"),
               says: Bilingual("I want to go home.", uk: "Я хочу додому."),
               symbol: "house.fill", kind: .action),
    ]

    // MARK: - Lookup

    /// Any cell or quick phrase by id, for auditory prompts and the story.
    static func phrase(id: String) -> Phrase? {
        if let quickPhrase = quick.first(where: { $0.id == id }) { return quickPhrase }
        for topic in Topic.allCases {
            if let phrase = topic.phrases.first(where: { $0.id == id }) { return phrase }
        }
        return nil
    }
}
