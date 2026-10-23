/// Every string Holos Words shows, in both languages.
///
/// The sentences the person says live in `Vocabulary`; these are the words
/// around them — the tour, the guide, the board's own controls. Plain
/// words throughout: the people this is for may read slowly, and a judge
/// has three minutes. Ukrainian uses «» quotes and ’ for the apostrophe.
enum Copy {
    // MARK: - App

    /// The Latin brand in both languages: Core's own strings say «Holos» in
    /// Ukrainian too, and one product should not wear two names on screen.
    static let appName = Bilingual("Holos Words", uk: "Holos Words")
    /// "Step 2 of 4" — the judged flow has four parts.
    static func stepOf(_ part: Int) -> Bilingual {
        Bilingual("Step \(part) of 4", uk: "Крок \(part) з 4")
    }
    static let restart = Bilingual("Start the tour again", uk: "Почати тур знову")
    static let restartHint = Bilingual(
        "Goes back to the beginning of the three-minute tour.",
        uk: "Повертає на початок тримінутного туру."
    )

    // MARK: - Step 1: the problem

    static let problemKicker = Bilingual("The problem", uk: "Проблема")
    static let nurseName = Bilingual("Nurse", uk: "Медсестра")
    /// Said by the nurse, on screen only: the synthesizer speaks only for the person.
    static let nurseAsks = Bilingual("Who should we call?", uk: "Кому нам подзвонити?")
    static let callMyStem = Bilingual("Call my", uk: "Подзвоніть")
    /// The word that is "right there": drawn faint and blurred inside the blank.
    static let ghostWord = Bilingual("wife", uk: "моїй дружині")
    static let problemTitle = Bilingual(
        "The word is right there. It won’t come.",
        uk: "Слово крутиться на язиці — і не згадується."
    )
    static let problemBody = Bilingual(
        "After a stroke or a brain injury, many people know exactly what they mean, but the word will not come. It is called anomia, the most common sign of aphasia. Typing does not help: aphasia can take spelling and reading too.",
        uk: "Після інсульту чи травми мозку людина часто точно знає, що хоче сказати, але не може згадати потрібне слово. Це називається аномія — найчастіша ознака афазії. Написати слово теж не вийде: афазія може забрати й письмо, і читання."
    )
    /// Yuriy is an illustrative persona, and the copy says so.
    static let problemExample = Bilingual(
        "For example, Yuriy, 48: he can read, but after his stroke he cannot find his words.",
        uk: "Наприклад, Юрій, 48 років: він може читати, але після інсульту не знаходить слів."
    )
    static let problemTry = Bilingual(
        "You can’t speak or type. You can only press one button. Try it.",
        uk: "Ви не можете ні говорити, ні писати. Можете лише натиснути одну кнопку. Спробуйте."
    )
    /// Touch mode and VoiceOver: there is no single switch, so a finger tries
    /// to answer by tapping the scene.
    static let problemTryTouch = Bilingual(
        "You can’t speak or type. Try to answer.",
        uk: "Ви не можете ні говорити, ні писати. Спробуйте відповісти."
    )
    static let problemNothing = Bilingual("Nothing. The word won’t come.", uk: "Нічого. Слово не згадується.")
    static let problemBegin = Bilingual(
        "Press anywhere, or Space, to begin",
        uk: "Натисніть будь-де або пробіл, щоб почати"
    )
    static let begin = Bilingual("Begin", uk: "Почати")
    /// Announced when Begin appears under VoiceOver or in touch mode, where
    /// "press anywhere" would be untrue.
    static let problemReady = Bilingual("Ready. Choose Begin.", uk: "Готово. Оберіть «Почати».")
    static let beginHint = Bilingual("Opens the board.", uk: "Відкриває дошку.")

    // MARK: - Step 2: two choices, one sentence

    static let twoChoicesTitle = Bilingual("Two choices, one sentence", uk: "Обрати двічі — і речення готове")
    static let twoChoicesGoal = Bilingual(
        "Say: “I feel pain. I need medicine.”",
        uk: "Скажіть: «Мені боляче. Мені потрібні ліки»."
    )
    static let twoChoicesHelpScan = Bilingual(
        "Pick a starter, and the board offers only the words that fit it. The yellow ring moves by itself: press when it reaches what you want. Follow the Next tag.",
        uk: "Оберіть початок речення — і дошка запропонує лише слова, що до нього пасують. Жовта рамка рухається сама: натисніть, коли вона дійде до потрібного. Орієнтуйтеся на позначку «Сюди»."
    )
    static let twoChoicesHelpTouch = Bilingual(
        "Tap a starter, then a word that fits it. Follow the Next tag.",
        uk: "Торкніться початку речення, а тоді слова, що пасує. Орієнтуйтеся на позначку «Сюди»."
    )

    // MARK: - Step 3: find the word

    static let findTitle = Bilingual("Find the word", uk: "Знайдіть слово")
    static let findGoal = Bilingual(
        "Say: “Please call my wife.”",
        uk: "Скажіть: «Подзвоніть, будь ласка, моїй дружині»."
    )
    static let findHelp = Bilingual(
        "“Wife” is not on the board: no board holds every word. Choose “Call my…”, then “Find a word”, and describe her instead of naming her.",
        uk: "Слова «дружина» на дошці немає: жодна дошка не вмістить усіх слів. Оберіть «Подзвоніть…», потім «Знайти слово» — і опишіть її, а не називайте."
    )

    // MARK: - Guide

    /// «Сюди» ("this way"), not «Далі»: that is the word on every Continue
    /// button, and on a cell it would read as a control. It needs no gender
    /// agreement either, on cells, starters and buttons alike.
    static let nextTag = Bilingual("Next", uk: "Сюди")
    static let showMe = Bilingual("Show me", uk: "Показати")
    static let showMeHint = Bilingual("Takes the next step for you.", uk: "Робить наступний крок за вас.")
    static let skipStep = Bilingual("Skip this step", uk: "Пропустити крок")
    static let skipStepHint = Bilingual("Moves on to the next part of the tour.", uk: "Переходить до наступної частини туру.")
    static let helpOffered = Bilingual(
        "Stuck? “Show me” takes the next step for you.",
        uk: "Не виходить? «Показати» зробить наступний крок за вас."
    )
    static func youSaid(_ words: Bilingual) -> Bilingual {
        // Ukrainian puts a sentence's full stop after the closing », while a
        // question mark stays inside: «Де мій телефон?».
        func quoted(_ sentence: String) -> String {
            sentence.hasSuffix(".") ? "«\(sentence.dropLast())»." : "«\(sentence)»"
        }
        return Bilingual(
            "You said: “\(words.en)”",
            uk: "Ви сказали: " + quoted(words.uk),
            ukFeminine: words.ukFeminine.map { "Ви сказали: " + quoted($0) }
        )
    }

    // MARK: - Board

    static let sentenceRow = Bilingual("Sentence", uk: "Речення")
    static let sentencePlaceholder = Bilingual("Choose a starter below", uk: "Оберіть початок речення нижче")
    static let startersRow = Bilingual("Starters", uk: "Початки речень")
    static let wordsRow = Bilingual("Words", uk: "Слова")
    static let starterHint = Bilingual(
        "Starts a sentence. The board then offers the words that fit it.",
        uk: "Починає речення. Дошка запропонує слова, що до нього пасують."
    )
    static let deleteHint = Bilingual(
        "Removes the open blank, or the last sentence.",
        uk: "Прибирає відкритий пропуск або останнє речення."
    )
    static let clearHint = Bilingual("Clears every sentence.", uk: "Стирає всі речення.")
    /// "No, keep it" inside a scanned Clear.
    static let clearCancelHint = Bilingual("Keeps your sentences as they are.", uk: "Залишає речення як є.")
    static let languageCell = Bilingual("Switch language", uk: "Змінити мову")

    static func wordsFor(_ starter: Bilingual) -> Bilingual {
        Bilingual("Words for “\(starter.en)”", uk: "Слова для «\(starter.uk)»")
    }

    /// "I need … blank", for VoiceOver.
    static func withBlank(_ stem: Bilingual) -> Bilingual {
        Bilingual("\(stem.en) … blank", uk: "\(stem.uk) … пропуск")
    }

    static func added(_ sentence: Bilingual) -> Bilingual {
        Bilingual(
            "Added: \(sentence.en)",
            uk: "Додано: \(sentence.uk)",
            ukFeminine: sentence.ukFeminine.map { "Додано: \($0)" }
        )
    }

    /// A filler's hint: the whole sentence it will say.
    static func finishes(_ sentence: Bilingual) -> Bilingual {
        Bilingual(
            "Adds the sentence: \(sentence.en)",
            uk: "Додає речення: \(sentence.uk)",
            ukFeminine: sentence.ukFeminine.map { "Додає речення: \($0)" }
        )
    }

    // MARK: - Find a word

    static let findWord = Bilingual("Find a word", uk: "Знайти слово")
    static let findStripTitle = Bilingual("Not here? Find a word", uk: "Немає потрібного? Знайти слово")
    static let findStripDetail = Bilingual(
        "Describe it: a person, a thing, a place…",
        uk: "Опишіть його: людина, річ, місце…"
    )
    static let findStripHint = Bilingual(
        "Finds a word that is not on the board, by describing it.",
        uk: "Знаходить слово, якого немає на дошці, через опис."
    )
    static let categoryHint = Bilingual("Narrows the search.", uk: "Звужує пошук.")
    static let findBackHint = Bilingual(
        "Goes back one question, or back to the board.",
        uk: "Повертає на одне питання назад або до дошки."
    )

    static func startsWith(_ cue: String) -> Bilingual {
        Bilingual("Starts with \(cue)", uk: "Починається на «\(cue)»")
    }

    // MARK: - Head turn

    static let headLead = Bilingual("Optional · about 20 seconds", uk: "За бажанням · близько 20 секунд")
    static let headFoot = Bilingual(
        "The camera stays off unless you turn it on. Skip is lit first.",
        uk: "Камера вимкнена, доки ви її не ввімкнете. «Пропустити» підсвічено першим."
    )
    /// Touch mode and VoiceOver: nothing is lit, so the footer says less.
    static let headFootTouch = Bilingual(
        "The camera stays off unless you turn it on.",
        uk: "Камера вимкнена, доки ви її не ввімкнете."
    )

    // MARK: - Step 4: hear it in Ukrainian

    static let ukrainianTitle = Bilingual("Hear it in Ukrainian", uk: "Почуйте це українською")
    static let ukrainianHeadline = Bilingual(
        "Every sentence whole, and correct",
        uk: "Кожне речення — ціле й правильне"
    )
    static let ukrainianBody = Bilingual(
        "Ukrainian changes a word to fit its sentence. “Wife” is «дружина», but “call my wife” needs «моїй дружині». Gluing a starter to a word would come out as broken Ukrainian. So Holos Words never glues: every sentence is stored whole, written for each starter, ready for a Ukrainian speech therapist to check.",
        uk: "В українській мові слово змінюється залежно від речення: «дружина», але «подзвоніть моїй дружині». Якщо просто приклеїти слово до початку речення, вийде ламана українська. Тому Holos Words нічого не склеює: кожне речення зберігається цілим, окремо для кожного початку, і його може перевірити український логопед."
    )
    /// Under Core's "No Ukrainian voice on this device". Core's own body says
    /// speech falls back to English, which is not true here: this page only
    /// ever plays Ukrainian, so without the voice it plays nothing.
    static let noVoiceStep4 = Bilingual(
        "So the sentences below can’t be played here. They are shown in Ukrainian instead. To add the voice on iPad: Settings › Accessibility › Spoken Content › Voices › Ukrainian. On a Mac: System Settings › Accessibility › Spoken Content › System voice › Manage Voices.",
        uk: "Тому речення нижче тут не прозвучать — їх показано українською. Щоб додати голос на iPad: Параметри › Доступність › Усний контент › Голоси › Українська. На Mac: Системні параметри › Доступність › Усний контент › Системний голос › Керувати голосами."
    )
    static let hearAgain = Bilingual("Hear them again", uk: "Послухати ще раз")
    static let hearAgainHint = Bilingual(
        "Plays the sentences in Ukrainian again.",
        uk: "Ще раз програє речення українською."
    )
    static let continueOn = Bilingual("Continue", uk: "Далі")
    static let continueHint = Bilingual("Goes on to the last screen.", uk: "Переходить до останнього екрана.")

    // MARK: - Closing

    static let closingTitle = Bilingual("A voice that offers the word", uk: "Голос, що підказує слово")
    static let closingWho = Bilingual(
        "Holos is for adults who lost speech to a stroke, a brain injury or war trauma. Rehabilitation centres in Ukraine treat many service members who struggle to communicate after brain injuries and strokes, often through aphasia.",
        uk: "Holos — для дорослих, які втратили мовлення через інсульт, травму мозку чи війну. Реабілітаційні центри в Україні лікують багатьох військових, яким після травм мозку та інсультів важко спілкуватися — часто через афазію."
    )
    static let closingPeople = Bilingual(
        "For example: Yuriy can read but cannot find his words. Mykola reads only simple words and presses one switch with his left hand. Oleksandr can move only his head.",
        uk: "Наприклад: Юрій читає, але не знаходить слів. Микола читає лише прості слова й натискає один перемикач лівою рукою. Олександр може рухати тільки головою."
    )
    static let closingWhy = Bilingual(
        "It is free, because a voice should not be a subscription. It is private: no account, no analytics, nothing leaves this device. And it is open source, so therapists can check every Ukrainian sentence and anyone can keep it alive.",
        uk: "Він безкоштовний, бо голос не має бути платною підпискою. Він приватний: без облікового запису, без аналітики, ніщо не залишає цей пристрій. І він з відкритим кодом — тож логопеди можуть перевірити кожне українське речення, а будь-хто може підтримувати й розвивати його далі."
    )
    static let keepTalking = Bilingual("Keep talking", uk: "Говорити далі")
    static let keepTalkingHint = Bilingual(
        "Opens the whole board to use freely.",
        uk: "Відкриває всю дошку для вільного користування."
    )
    static let startAgain = Bilingual("Start again", uk: "Почати знову")
    static let startAgainHint = Bilingual(
        "Plays the three-minute tour again from the beginning.",
        uk: "Ще раз показує тримінутний тур від початку."
    )
}
