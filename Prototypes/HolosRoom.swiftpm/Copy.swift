/// Every word Holos Room shows that is not a phrase on the board.
///
/// The phrases live in `Vocabulary`; the shared core's words in `CoreCopy`.
/// Everything here is the story around the board: the nurse, the cards,
/// the hints. Characters other than the person never speak aloud — the
/// voice belongs to the person — so the nurse's lines are text only.
enum Copy {
    // MARK: - Places

    static let placeWard = Bilingual("Ward", uk: "Палата")
    static let placeHome = Bilingual("Home", uk: "Дім")
    /// The chip that goes from the ward to home.
    static let goHome = Bilingual("Go home", uk: "Додому")
    /// The chip that goes from home back to the ward.
    static let goWard = Bilingual("To the ward", uk: "До палати")
    static let placeChipHint = Bilingual("Changes the room.", uk: "Змінює кімнату.")

    /// One sentence each, so a VoiceOver user knows what the picture holds
    /// before meeting its objects one by one.
    static let wardDescription = Bilingual(
        "A hospital ward at dusk: a window with curtains, the bed, a body chart on the wall, a phone on a shelf, a bedside table with water, pills and glasses, and a nurse at the door.",
        uk: "Лікарняна палата в сутінках: вікно зі шторами, ліжко, схема тіла на стіні, телефон на полиці, тумбочка з водою, ліками й окулярами, і медсестра у дверях."
    )
    static let homeDescription = Bilingual(
        "A living room at dusk: the fridge, a kettle on the counter, a family photo, the sofa, the TV and the front door.",
        uk: "Вітальня в сутінках: холодильник, чайник на стільниці, сімейне фото, диван, телевізор і вхідні двері."
    )

    // MARK: - The board

    static let hotspotHint = Bilingual("Shows what you can say about this.", uk: "Показує, що можна про це сказати.")
    static let topicHint = Bilingual("Shows what you can say about this person.", uk: "Показує, що можна сказати про цю людину.")
    /// Read as the value of whatever the guide marker points at.
    static let nextStep = Bilingual("Next step", uk: "Наступний крок")
    /// The language chip names the OTHER language in the current one, so
    /// the scan prompt never hands Cyrillic to an English voice.
    static let languageChip = Bilingual("Ukrainian", uk: "Англійська")
    static let paused = Bilingual("Paused. Press to scan again.", uk: "Пауза. Натисніть, щоб сканувати знову.")
    static let youSaid = Bilingual("You said", uk: "Ви сказали")
    static let nurseSays = Bilingual("The nurse says", uk: "Медсестра каже")
    /// The empty bubble in step 1: a press with nothing to choose.
    static let silence = Bilingual("…", uk: "…")
    static let silenceLabel = Bilingual("You try to answer, but no words come.", uk: "Ви намагаєтеся відповісти, але слів немає.")

    // MARK: - Help when stuck

    static let helpChip = Bilingual("Show me", uk: "Показати")
    static let helpChipHint = Bilingual("Says the next part of the goal for you.", uk: "Промовляє наступну частину завдання за вас.")
    static let helpOfferedScanning = Bilingual(
        "Stuck? “Show me” now lights up first: one press does the next part.",
        uk: "Не виходить? Тепер першою підсвічується кнопка «Показати»: одне натискання зробить наступний крок."
    )
    static let helpOfferedTouch = Bilingual(
        "Stuck? Tap “Show me” to see the next part done.",
        uk: "Не виходить? Торкніться «Показати», щоб побачити наступний крок."
    )

    // MARK: - Hints along the way

    /// Quotes, not grammar: Ukrainian would decline "the bed" after "до",
    /// but a name in «» stays as it is printed on the pill.
    static func hintReach(_ name: Bilingual, scanning: Bool) -> Bilingual {
        scanning
            ? Bilingual("Press when “\(name.en)” lights up.", uk: "Натисніть, коли засвітиться «\(name.uk)».")
            : Bilingual("Tap “\(name.en)”.", uk: "Торкніться «\(name.uk)».")
    }

    /// While scanning, a touch picks whatever is lit, not the cell under the
    /// finger, so the scanning hints say when to press, never where.
    static func hintChoose(_ label: Bilingual, scanning: Bool) -> Bilingual {
        let feminine = label.ukFeminine
        return scanning
            ? Bilingual(
                "Now press when “\(label.en)” lights up.",
                uk: "Тепер натисніть, коли засвітиться «\(label.uk)».",
                ukFeminine: feminine.map { "Тепер натисніть, коли засвітиться «\($0)»." }
            )
            : Bilingual(
                "Tap “\(label.en)”.",
                uk: "Торкніться «\(label.uk)».",
                ukFeminine: feminine.map { "Торкніться «\($0)»." }
            )
    }

    static func hintGoBack(scanning: Bool) -> Bilingual {
        scanning
            ? Bilingual("Not here: press when “Go back” lights up, or just wait.", uk: "Не тут: натисніть, коли засвітиться «Назад», або просто зачекайте.")
            : Bilingual("Not here: tap “Go back”.", uk: "Не тут: торкніться «Назад».")
    }

    // MARK: - Parts of the story

    static let partNames: [Bilingual] = [
        Bilingual("The problem", uk: "Проблема"),
        Bilingual("One switch", uk: "Один перемикач"),
        Bilingual("Familiar places", uk: "Знайомі місця"),
        Bilingual("Ukrainian", uk: "Українською"),
    ]

    static func partLabel(_ number: Int, of total: Int) -> Bilingual {
        Bilingual("Part \(number) of \(total)", uk: "Частина \(number) з \(total)")
    }

    // MARK: - 1. The problem

    static let problemTitle = Bilingual("Feel the problem", uk: "Відчуйте проблему")
    static let nurseAsks = Bilingual("How are you feeling?", uk: "Як ви почуваєтеся?")
    static let problemAskTitle = Bilingual("You can hear her. You can't answer.", uk: "Ви її чуєте. Але не можете відповісти.")
    /// Mykola is an illustrative example, introduced as one.
    static let problemAskBody = Bilingual(
        "Imagine you are Mykola, 39. A stroke took your speech and your right hand. You have one button. Press it.",
        uk: "Уявіть, що ви Микола, вам 39. Інсульт забрав мовлення і праву руку. У вас є одна кнопка. Натисніть її."
    )
    static let problemSilentTitle = Bilingual(
        "You can see everything you need. You just can't say it.",
        uk: "Ви бачите все, що потрібно. Просто не можете цього сказати."
    )
    static let problemSilentBody = Bilingual(
        "A press with nothing to choose is silence. Holos gives that one press a whole room of words.",
        uk: "Натискання, коли нема з чого обрати, — це тиша. Holos дає цьому одному натисканню цілу кімнату слів."
    )

    // MARK: - 2. One switch, any message

    static let scanTitle = Bilingual("One switch, any message", uk: "Один перемикач — будь-яке повідомлення")
    static let scanGoal = Bilingual(
        "Tell the nurse: “I'm in pain. Medicine, please.”",
        uk: "Скажіть медсестрі: «Мені боляче. Ліки, будь ласка»."
    )
    static let scanHow = Bilingual(
        "The light moves around the room. One press opens a place; the next says a phrase.",
        uk: "Світло рухається кімнатою. Одне натискання відкриває місце, наступне промовляє фразу."
    )
    static let scanHowTouch = Bilingual(
        "Tap a place in the room, then tap what you want to say.",
        uk: "Торкніться місця в кімнаті, а тоді — того, що хочете сказати."
    )
    static let nurseMedicine = Bilingual("I'll bring your medicine right away.", uk: "Зараз принесу вам ліки.")
    static let nurseUnderstood = Bilingual("I understand. I'll be right back.", uk: "Я зрозуміла. Зараз повернуся.")
    static let scanDoneTitle = Bilingual("She understood you.", uk: "Вона вас зрозуміла.")
    static let scanDoneBody = Bilingual(
        "No speech, no typing: a few presses of one switch. A tap, a key, a game controller or a head turn all make the same press.",
        uk: "Без мовлення, без клавіатури — кілька натискань одного перемикача. Дотик, клавіша, ігровий контролер чи поворот голови — це те саме натискання."
    )

    // MARK: - 3. Familiar places

    static let familiarTitle = Bilingual("Familiar places", uk: "Знайомі місця")
    static let familiarIntroTitle = Bilingual("A familiar room brings words back.", uk: "Знайома кімната повертає слова.")
    /// "Suggests", and no numbers: the research is promising, not settled.
    static let familiarIntroBody = Bilingual(
        "Yuriy, 48, can read, but since his stroke the words he wants will not come. Research on visual scene displays suggests that for adults with severe aphasia, words anchored in a familiar scene are easier to find than the same words in a grid. Let's go home.",
        uk: "Юрій, 48 років, уміє читати, але після інсульту не може знайти потрібних слів. Дослідження дошок-сцен дають підстави вважати, що дорослим із тяжкою афазією легше знайти слова, прив’язані до знайомої сцени, ніж ті самі слова в таблиці. Ходімо додому."
    )
    static let familiarGoal = Bilingual(
        "Ask: “Please call my wife.”",
        uk: "Попросіть: «Подзвоніть моїй дружині, будь ласка»."
    )
    static let familiarHow = Bilingual(
        "The word “wife” will not come to Yuriy. The family photo offers it.",
        uk: "Слово «дружина» не спадає Юрієві на думку. Сімейне фото підказує його."
    )
    static let familiarDoneTitle = Bilingual("The photo offered the word.", uk: "Фото підказало слово.")
    /// "In the photo", not "her face": the prototype's people are generic
    /// symbols with their names printed. With the person's own photos the
    /// face itself would be the cue.
    static let familiarDoneBody = Bilingual(
        "Yuriy did not have to recall “wife”. He recognised her in the photo, and the words were waiting beside her. The room is the memory cue.",
        uk: "Юрієві не довелося згадувати слово «дружина». Він упізнав її на фото, а слова чекали поруч. Кімната — це підказка для пам’яті."
    )
    static let familiarOtherTitle = Bilingual("You said it your way.", uk: "Ви сказали це по-своєму.")
    static let familiarOtherBody = Bilingual(
        "Every choice is a message. For Yuriy, the family photo offers “wife” when the word will not come.",
        uk: "Кожен вибір — це повідомлення. Юрієві сімейне фото підказує слово «дружина», коли воно не спадає на думку."
    )

    // MARK: - 4. Hear it in Ukrainian

    static let ukrainianTitle = Bilingual("Hear it in Ukrainian", uk: "Почуйте українською")
    static let ukrainianBody = Bilingual(
        "Your message, the same presses — now in the language of the people Holos is for.",
        uk: "Ваше повідомлення, ті самі натискання — тепер мовою людей, для яких створено Holos."
    )
    static let sayInUkrainian = Bilingual("Say it in Ukrainian", uk: "Сказати українською")
    static let sayAgain = Bilingual("Say it again", uk: "Сказати ще раз")
    static let sayInUkrainianHint = Bilingual(
        "Switches the board to Ukrainian and speaks your message.",
        uk: "Перемикає дошку на українську і промовляє ваше повідомлення."
    )
    static let ukrainianAfter = Bilingual(
        "Every phrase is written and spoken in both languages, so the same room works in a Kyiv hospital and a UK clinic.",
        uk: "Кожна фраза написана й озвучена обома мовами, тож та сама кімната працює і в київській лікарні, і в британській клініці."
    )

    // MARK: - Closing

    static let closingTitle = Bilingual("Holos: a voice, one press at a time", uk: "Holos: голос — натискання за натисканням")
    /// Kept short: the closing card has to fit the three-minute budget, and
    /// `closingSource` already names Mykola, Oleksandr and Yuriy as examples.
    static let closingWho = Bilingual(
        "For Ukrainian adults who lost speech through stroke, brain injury or war trauma, and for the families and therapists beside them.",
        uk: "Для дорослих українців, які втратили мовлення через інсульт, черепно-мозкову травму чи наслідки війни, і для їхніх родин та терапевтів мови й мовлення."
    )
    static let closingWhy = Bilingual(
        "Rehabilitation centres in Ukraine treat many service members recovering from brain injuries and strokes who struggle to communicate. Aphasia can take reading and spelling as well as speech, so a keyboard is not enough.",
        uk: "Реабілітаційні центри в Україні лікують багатьох військових, яким після черепно-мозкових травм та інсультів важко спілкуватися. Афазія може забрати не лише мовлення, а й читання та письмо, тож клавіатури недостатньо."
    )
    static let closingFree = Bilingual(
        "Free, private (no account, no analytics, nothing leaves the device) and open source, so anyone can check it, translate it and keep it alive.",
        uk: "Безкоштовний, приватний (без облікового запису, без аналітики, ніщо не залишає пристрій) і з відкритим кодом, тож будь-хто може його перевірити, перекласти й підтримувати."
    )
    /// The English line spells the NGO's Ukrainian name in Latin letters:
    /// it is read by an English voice, and Cyrillic handed to one is not
    /// accented, it is unintelligible.
    static let closingSource = Bilingual(
        "Source on rehabilitation: the Talk! (Hovory!) NGO. Mykola, Oleksandr and Yuriy are illustrative examples.",
        uk: "Джерело про реабілітацію: ГО «Говори!» (Talk!). Микола, Олександр і Юрій — умовні приклади."
    )
    static let keepTalking = Bilingual("Keep talking", uk: "Говорити далі")
    static let keepTalkingHint = Bilingual("Opens the room to use freely.", uk: "Відкриває кімнату для вільного користування.")
    static let startAgain = Bilingual("Start again", uk: "Почати знову")
    static let startAgainHint = Bilingual("Plays the story from the beginning.", uk: "Показує історію з початку.")

    // MARK: - Free board

    static let freeTitle = Bilingual("Your room", uk: "Ваша кімната")
    static let freeHow = Bilingual(
        "Choose a place, then what to say. Every choice speaks at once and joins your message below.",
        uk: "Оберіть місце, а тоді — що сказати. Кожен вибір звучить одразу й додається до повідомлення внизу."
    )

    // MARK: - Moving on

    static let pressToContinue = Bilingual(
        "Press anywhere, or Space, to continue",
        uk: "Натисніть будь-де або пробіл, щоб продовжити"
    )
    static let continueButton = Bilingual("Continue", uk: "Далі")
    static let continueHint = Bilingual("Goes to the next part.", uk: "Переходить до наступної частини.")
}
