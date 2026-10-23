/// Every word Holos Grid shows that is not a board cell, in both languages.
///
/// One file on purpose: a wording pass — or a speech therapist reviewing the
/// Ukrainian — touches exactly this file and `Vocabulary.swift`, nothing else.
/// The cells' own words live with the cells, in `Vocabulary.swift`.
///
/// Voice: plain, adult, never cute. The people this is for are grown men and
/// women who have lost speech, not children learning it.
enum Copy {
    // MARK: - Chrome

    /// One brand in both languages. "Голос" is what the name means, and the
    /// essays can say so; on screen a second spelling would read as a
    /// second app.
    static let appName = Bilingual("Holos", uk: "Holos")
    static let restartTour = Bilingual("Start the tour again", uk: "Почати тур знову")
    static let restartTourHint = Bilingual(
        "Goes back to the beginning of the three-minute tour.",
        uk: "Повертає на початок трихвилинного туру."
    )

    /// The step line under the name, e.g. "Step 2 of 4 · One switch, any message".
    static func stepLine(_ step: FlowStep) -> Bilingual {
        switch step {
        case .problem: numbered(1, problemTitle)
        case .oneSwitch: numbered(2, oneSwitchTitle)
        case .aphasia: numbered(3, aphasiaTitle)
        case .ukrainian: numbered(4, ukrainianTitle)
        case .closing: numbered(4, closingTitle)
        case .free: freeTitle
        }
    }

    private static func numbered(_ number: Int, _ title: Bilingual) -> Bilingual {
        Bilingual("Step \(number) of 4 · \(title.en)", uk: "Крок \(number) з 4 · \(title.uk)")
    }

    // MARK: - Narrative controls

    static let pressToStart = Bilingual("Press to start", uk: "Натисніть, щоб почати")
    static let pressToContinue = Bilingual("Press to continue", uk: "Натисніть, щоб продовжити")
    static let continueHint = Bilingual("Moves on to the next part.", uk: "Переходить до наступної частини.")

    // MARK: - Step 1 · The problem

    static let problemTitle = Bilingual("Feel the problem", uk: "Відчуйте проблему")
    /// Mykola is an illustration, so the copy says "someone like".
    static let problemPersona = Bilingual(
        "Imagine you are someone like Mykola, 39. A stroke has taken your speech and the use of your right hand.",
        uk: "Уявіть себе на місці когось на кшталт Миколи, якому 39. Інсульт позбавив вас мовлення, а права рука вас не слухається."
    )
    static let problemBody = Bilingual(
        "You hear everything and understand everything. You cannot speak, and you cannot write. All you can do is press once.",
        uk: "Ви все чуєте й усе розумієте. Ви не можете говорити й не можете писати. Усе, що ви можете, — один раз натиснути."
    )
    static let nurse = Bilingual("Nurse", uk: "Медсестра")
    /// What the nurse says, one line per press. She speaks only on screen:
    /// the synthesiser is the person's voice and nobody else's.
    static let nurseLines: [Bilingual] = [
        Bilingual("How are you feeling?", uk: "Як ви почуваєтеся?"),
        Bilingual("…", uk: "…"),
        Bilingual("Are you all right?", uk: "З вами все гаразд?"),
        Bilingual("Can you hear me?", uk: "Ви мене чуєте?"),
    ]

    /// Never out of range, whatever index a caller hands it.
    static func nurseLine(_ index: Int) -> Bilingual {
        if nurseLines.indices.contains(index) { return nurseLines[index] }
        return nurseLines.last ?? Bilingual("…", uk: "…")
    }

    static let switchLabel = Bilingual("Press", uk: "Натиснути")
    static let switchBegin = Bilingual("Begin", uk: "Почати")
    /// Heard only by VoiceOver users, for whom the whole-screen tap area is
    /// off and VoiceOver itself says how to activate — so it says what the
    /// switch means, not how to press it.
    static let switchHint = Bilingual(
        "Your only switch. Pressing it is all you can do here.",
        uk: "Ваш єдиний перемикач. Натиснути його — це все, що ви можете."
    )
    static let problemReveal = Bilingual(
        "Holos turns that one press into a voice.",
        uk: "Holos перетворює це одне натискання на голос."
    )

    // MARK: - Step 2 · One switch

    static let oneSwitchTitle = Bilingual("One switch, any message", uk: "Один перемикач — будь-яке повідомлення")
    static let oneSwitchHowScanning = Bilingual(
        "Rows light up one after another. Press when your row is lit, then press again when your cell is lit.",
        uk: "Ряди підсвічуються по черзі. Натисніть, коли світиться ваш ряд, і ще раз — коли світиться ваша клітинка."
    )
    static let oneSwitchHowTouch = Bilingual(
        "Touch is on: tap the cells to build the message, then tap Speak.",
        uk: "Увімкнено дотик: торкайтеся клітинок, щоб скласти повідомлення, а тоді — «Сказати»."
    )
    static let oneSwitchTip = Bilingual(
        "The yellow ring shows what a press will pick. The navy “Next” tag shows where to go.",
        uk: "Жовта рамка показує, що обере натискання. Синя позначка «Далі» показує, куди йти."
    )
    static let reminderScanning = Bilingual(
        "Press once for a row, once more for a cell.",
        uk: "Натисніть раз — ряд, ще раз — клітинка."
    )
    static let reminderTouch = Bilingual("Tap the cells, then Speak.", uk: "Торкайтеся клітинок, а тоді — «Сказати».")
    static let goalSay = Bilingual("Say", uk: "Скажіть")
    static let successOneTitle = Bilingual("You said it.", uk: "Ви це сказали.")
    /// After "Show me": Holos did the building, so the card says so and
    /// counts no presses — credit the person did not earn would ring false.
    static let successShown = Bilingual(
        "Holos built it for you this time. Your switch takes exactly the same path.",
        uk: "Цього разу повідомлення склав Holos. Ваш перемикач пройде тим самим шляхом."
    )
    static let successTouch = Bilingual(
        "Every word came from a picture you recognised, not from a keyboard.",
        uk: "Кожне слово — з малюнка, який ви впізнали, а не з клавіатури."
    )

    static func presses(_ count: Int) -> Bilingual {
        Bilingual("Presses: \(count)", uk: "Натискань: \(count)")
    }

    static func successPresses(_ count: Int) -> Bilingual {
        Bilingual(
            "\(count) \(count == 1 ? "press" : "presses"). One movement, a whole sentence.",
            uk: "\(count) \(ukrainianPresses(count)). Один рух — ціле речення."
        )
    }

    /// Ukrainian counts nouns three ways; "натискання" happens to share its
    /// singular and few-form, so only the many-form differs.
    private static func ukrainianPresses(_ count: Int) -> String {
        let lastTwo = count % 100
        let last = count % 10
        if (11...14).contains(lastTwo) || last == 0 || last >= 5 { return "натискань" }
        return "натискання"
    }

    // MARK: - Step 3 · The aphasia board

    static let aphasiaTitle = Bilingual("The aphasia board", uk: "Дошка для людей з афазією")
    /// Yuriy is an illustration too.
    static let aphasiaStory = Bilingual(
        "Think of someone like Yuriy, 48. He can read, but since his stroke the words won’t come when he needs them. He wants his wife — and cannot find the word “wife”.",
        uk: "Уявіть когось на кшталт Юрія, 48 років. Він уміє читати, але після інсульту потрібні слова не спадають йому на думку саме тоді, коли треба. Він хоче, щоб подзвонили його дружині, — і не може згадати слово «дружина»."
    )
    static let aphasiaPoint = Bilingual(
        "So the board does not ask him to remember. It offers the word: he only has to recognise it, and the cell says the whole sentence for him.",
        uk: "Тож дошка не вимагає від нього пригадувати слова. Вона пропонує слово — Юрію досить його впізнати, а клітинка сама скаже за нього ціле речення."
    )
    static let aphasiaRoute = Bilingual("Family → Wife → Speak", uk: "Родина → Дружина → Сказати")
    static let aphasiaReminder = Bilingual(
        "He can’t recall “wife”. Find it on the Family board.",
        uk: "Він не може згадати слово «дружина». Знайдіть його на дошці «Родина»."
    )
    static let successTwoTitle = Bilingual(
        "Recognised, not recalled: one word became a whole sentence.",
        uk: "Не згадати, а впізнати: одне слово стало цілим реченням."
    )

    // MARK: - Guidance

    static let guideNext = Bilingual("Next", uk: "Далі")
    static let showMe = Bilingual("Show me", uk: "Показати")
    static let showMeHint = Bilingual("Holos builds the message and says it for you.", uk: "Holos складе повідомлення і скаже його за вас.")
    static let stuckNote = Bilingual("No rush. Holos can show you.", uk: "Не поспішайте. Holos може показати.")
    static let scanPaused = Bilingual(
        "The scan is resting. Press to start it again.",
        uk: "Сканування призупинено. Натисніть, щоб почати знову."
    )

    /// Words in each language's own quotation marks: “…” and «…».
    static func quoted(_ words: Bilingual) -> Bilingual {
        Bilingual(
            "“\(words.en)”",
            uk: "«\(words.uk)»",
            ukFeminine: words.ukFeminine.map { "«\($0)»" }
        )
    }

    /// The one-line "where next" under the goal, shaped by what is missing.
    /// A cell's hint names its board: the quick row has its own "I’m in
    /// pain", scanned first, and "Next: I’m in pain" alone would point at it.
    static func nextHint(_ target: GuideTarget) -> Bilingual {
        switch target {
        case .cell(let phrase, let topic):
            Bilingual(
                "Next: “\(phrase.label.en)” on the \(topic.name.en) board",
                uk: "Далі: «\(phrase.label.uk)» на дошці «\(topic.name.uk)»",
                ukFeminine: phrase.label.ukFeminine.map { "Далі: «\($0)» на дошці «\(topic.name.uk)»" }
            )
        case .topic(let topic):
            Bilingual(
                "Next: open “\(topic.name.en)” in the topics row",
                uk: "Далі: відкрийте «\(topic.name.uk)» в ряду тем"
            )
        case .speak:
            Bilingual("Next: Speak, in the message row", uk: "Далі: «Сказати» в ряду повідомлення")
        }
    }

    // MARK: - Step 4 · Ukrainian

    static let ukrainianTitle = Bilingual("Hear it in Ukrainian", uk: "Почуйте це українською")
    static let ukrainianBody = Bilingual(
        "The same message on the same board — now in the language of the people Holos is for. English stays one tap away.",
        uk: "Те саме повідомлення на тій самій дошці — тепер мовою людей, для яких створено Holos. Англійська — за один дотик."
    )
    static let ukrainianGloss = Bilingual("In English:", uk: "Англійською:")

    // MARK: - Closing

    static let closingTitle = Bilingual("Who Holos is for", uk: "Для кого Holos")
    static let closingBody = Bilingual(
        "Ukrainian adults who have lost speech to a stroke, a brain injury or war trauma — and who may not be able to type, or to tap a small screen. Rehabilitation centres in Ukraine treat many service members who struggle to communicate after brain injuries and strokes.",
        uk: "Дорослі українці, які втратили мовлення через інсульт, травму мозку чи наслідки війни, — і, можливо, не можуть друкувати чи влучати пальцем у дрібні кнопки на екрані. Реабілітаційні центри в Україні лікують багатьох військових, яким після травм мозку та інсультів важко спілкуватися."
    )
    static let closingSource = Bilingual("Source: Talk! (Говори!), a Ukrainian NGO.", uk: "Джерело: громадська організація «Говори!».")
    static let pillarFree = Bilingual("Free", uk: "Безкоштовний")
    static let pillarFreeDetail = Bilingual("No price and no subscription.", uk: "Без оплати й без підписки.")
    static let pillarPrivate = Bilingual("Private", uk: "Приватний")
    static let pillarPrivateDetail = Bilingual(
        "No account, no analytics. Nothing leaves this device.",
        uk: "Без облікового запису й аналітики. Ніщо не залишає цей пристрій."
    )
    static let pillarOpen = Bilingual("Open source", uk: "Відкритий код")
    static let pillarOpenDetail = Bilingual(
        "Anyone can audit it, translate it, or keep it alive.",
        uk: "Будь-хто може перевірити його, перекласти чи підтримувати."
    )
    /// Scanning only: the two choices wait for a first press, made once the
    /// screen has been read, before they start lighting up.
    static let pressToChoose = Bilingual("Press to choose", uk: "Натисніть, щоб обрати")
    static let keepTalking = Bilingual("Keep talking", uk: "Говорити далі")
    static let keepTalkingHint = Bilingual("Opens the whole board to use freely.", uk: "Відкриває всю дошку для вільного користування.")
    static let startAgain = Bilingual("Start again", uk: "Почати знову")
    static let startAgainHint = Bilingual("Restarts the three-minute tour.", uk: "Починає трихвилинний тур спочатку.")

    // MARK: - Free board

    static let freeTitle = Bilingual("Your board", uk: "Ваша дошка")
    static let freeBody = Bilingual(
        "This is the real app: any message, either language, one switch.",
        uk: "Це і є застосунок: будь-яке повідомлення, українською чи англійською, одним перемикачем."
    )

    // MARK: - Board

    static let quickRow = Bilingual("Quick phrases", uk: "Швидкі фрази")
    static let topicsRow = Bilingual("Topics", uk: "Теми")
    static let topicHint = Bilingual("Shows this topic’s words.", uk: "Показує слова цієї теми.")

    static func topicRow(_ topic: Topic, _ number: Int) -> Bilingual {
        Bilingual("\(topic.name.en), row \(number)", uk: "\(topic.name.uk), ряд \(number)")
    }

    static let topicNeeds = Bilingual("Needs", uk: "Потреби")
    static let topicPain = Bilingual("Pain & body", uk: "Біль і тіло")
    /// "Лікування" (treatment), so the topic never reads the same as its own
    /// first cell, "Ліки" (medicine).
    static let topicMedicine = Bilingual("Medicine", uk: "Лікування")
    static let topicFamily = Bilingual("Family", uk: "Родина")
    static let topicFeelings = Bilingual("Feelings", uk: "Почуття")
    static let topicTalk = Bilingual("Talk", uk: "Розмова")
}
