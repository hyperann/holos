/// Every string the shared core shows or speaks, in both languages.
///
/// Each prototype keeps its own `Copy.swift` for its own words; these are
/// the ones all five share, so a wording fix here reaches all of them.
enum CoreCopy {
    // MARK: - Scanning

    static let goBack = Bilingual("Go back", uk: "Назад")
    static let goBackHint = Bilingual("Goes back one step, to where you were.", uk: "Повертає на крок назад, туди, де ви були.")

    // MARK: - Message bar

    static let messageEmpty = Bilingual("Your message appears here", uk: "Тут з’явиться ваше повідомлення")
    static let speak = Bilingual("Speak", uk: "Сказати")
    static let speakHint = Bilingual("Says the whole message aloud.", uk: "Промовляє все повідомлення вголос.")
    static let deleteLast = Bilingual("Delete last", uk: "Стерти останнє")
    static let clear = Bilingual("Clear", uk: "Очистити")
    /// The second press Clear needs when scanning — says exactly what it does.
    static let clearConfirm = Bilingual("Yes, clear all", uk: "Так, очистити все")
    /// Lit first inside Clear, so a double press keeps the message.
    static let clearCancel = Bilingual("No, keep it", uk: "Ні, залишити")
    static let messageLabel = Bilingual("Message", uk: "Повідомлення")

    // MARK: - Cells

    static let cellHintTouch = Bilingual("Adds this to your message.", uk: "Додає це до повідомлення.")
    static let cellHintSpeak = Bilingual("Says this aloud.", uk: "Промовляє це вголос.")

    // MARK: - Language

    static let languageLabel = Bilingual("Language", uk: "Мова")
    static let languageHint = Bilingual(
        "Switches every label and the voice to the other language.",
        uk: "Перемикає всі підписи й голос на іншу мову."
    )

    // MARK: - Voice notice

    static let noUkrainianVoiceTitle = Bilingual(
        "No Ukrainian voice on this device",
        uk: "На цьому пристрої немає українського голосу"
    )
    static let noUkrainianVoiceBody = Bilingual(
        "The board stays in Ukrainian; speech uses English for now. To add the voice: Settings › Accessibility › Spoken Content › Voices › Ukrainian.",
        uk: "Дошка залишається українською, а озвучення поки що — англійською. Щоб додати голос: Параметри › Доступність › Усний контент › Голоси › Українська."
    )

    // MARK: - Settings

    static let settingsButton = Bilingual("Settings", uk: "Налаштування")
    static let settingsButtonHint = Bilingual(
        "Switches, scanning speed, voice and language.",
        uk: "Перемикачі, швидкість сканування, голос і мова."
    )
    static let settingsTitle = Bilingual("Settings", uk: "Налаштування")
    static let done = Bilingual("Done", uk: "Готово")

    static let sectionChoosing = Bilingual("How you choose", uk: "Як ви обираєте")
    static let modeScanning = Bilingual("Scan with a switch", uk: "Сканування перемикачем")
    static let modeTouch = Bilingual("Touch the pictures", uk: "Торкатися малюнків")
    static let modeDetail = Bilingual(
        "Scanning lights the cells one by one; a single press picks the lit one. When VoiceOver or Switch Control is on, Holos steps aside and lets them drive.",
        uk: "Під час сканування клітинки підсвічуються по черзі; одне натискання обирає підсвічену. Коли ввімкнено VoiceOver або системне керування перемикачами, Holos вимикає власне сканування й передає керування їм."
    )

    static let sectionScanning = Bilingual("Scanning", uk: "Сканування")
    static let scanSpeed = Bilingual("Time on each cell", uk: "Час на кожній клітинці")
    static let pressGap = Bilingual("Ignore repeat presses for", uk: "Ігнорувати повторні натискання")
    static let pressGapDetail = Bilingual(
        "For a tremor or a switch that bounces: extra presses this soon after one are ignored.",
        uk: "Якщо тремтить рука або перемикач спрацьовує двічі, зайві натискання одразу після першого ігноруються."
    )
    static let auditoryPrompts = Bilingual("Read each cell aloud quietly", uk: "Тихо озвучувати кожну клітинку")
    static let auditoryPromptsDetail = Bilingual(
        "For anyone who finds the screen hard to see or read.",
        uk: "Для тих, кому важко роздивитися екран або прочитати написане."
    )

    static let sectionSwitches = Bilingual("Switches", uk: "Перемикачі")
    static let switchTap = Bilingual("Tap anywhere on the screen", uk: "Дотик будь-де на екрані")
    static let switchKey = Bilingual("Space or Enter key", uk: "Клавіша пробілу або Enter")
    static let switchController = Bilingual("Game controller button", uk: "Кнопка ігрового контролера")
    static let switchHead = Bilingual("Turn your head", uk: "Поворот голови")
    static let switchHeadDetail = Bilingual(
        "Turn your head to one side and hold it for a moment. The front camera is read frame by frame and nothing is recorded or sent.",
        uk: "Поверніть голову вбік і затримайте на мить. Зображення з фронтальної камери аналізується лише на цьому пристрої — нічого не записується й не надсилається."
    )
    static let connected = Bilingual("Connected", uk: "Під’єднано")
    static let notConnected = Bilingual("Not connected", uk: "Не під’єднано")
    static let alwaysOn = Bilingual("Always on", uk: "Завжди ввімкнено")
    static let headTurn = Bilingual("Turn needed", uk: "Потрібний поворот")
    static let headHold = Bilingual("Hold for", uk: "Утримувати")

    static let headOff = Bilingual("Off", uk: "Вимкнено")
    static let headAsking = Bilingual("Waiting for camera permission…", uk: "Очікуємо доступу до камери…")
    static let headDenied = Bilingual(
        "Camera not allowed. You can allow it in Settings, or use any other switch.",
        uk: "Доступ до камери не надано. Його можна надати в Параметрах або скористатися іншим перемикачем."
    )
    static let headNoCamera = Bilingual(
        "No front camera found. Tap, a key or a controller still work.",
        uk: "Фронтальної камери не знайдено. Дотик, клавіша чи контролер і далі працюють."
    )
    static let headSearching = Bilingual("Looking for your face…", uk: "Шукаємо ваше обличчя…")
    static let headTracking = Bilingual("Ready — turn your head and hold", uk: "Готово — поверніть голову й затримайте")
    static let headCalibrating = Bilingual("Hold still — finding your centre…", uk: "Тримайте голову нерухомо — визначаємо вихідне положення…")
    static let headRecenter = Bilingual("Set my centre again", uk: "Заново визначити вихідне положення")
    static let headRecenterHint = Bilingual(
        "Hold your head still in a comfortable position for a moment. Turns are measured from there.",
        uk: "Потримайте голову нерухомо в зручному положенні. Повороти рахуватимуться від нього."
    )

    static let sectionVoice = Bilingual("Voice and language", uk: "Голос і мова")
    static let speakerGender = Bilingual("Speak as", uk: "Говорити як")
    static let speakerGenderDetail = Bilingual(
        "Ukrainian changes some words for a man or a woman — “я втомився”, “я втомилася”.",
        uk: "В українській деякі слова залежать від роду — «я втомився», «я втомилася»."
    )
    static let genderMasculine = Bilingual("A man", uk: "Чоловік")
    static let genderFeminine = Bilingual("A woman", uk: "Жінка")
    static let speechRate = Bilingual("Speaking speed", uk: "Швидкість мовлення")
    static let ukrainianVoiceInstalled = Bilingual("Ukrainian voice installed", uk: "Український голос встановлено")
    static let ukrainianVoiceMissing = Bilingual("No Ukrainian voice installed", uk: "Український голос не встановлено")

    static let sectionFeedback = Bilingual("Feel and sound", uk: "Вібрація й звук")
    static let haptics = Bilingual("Vibration on each step", uk: "Вібрація на кожному кроці")
    static let hapticsUnavailable = Bilingual(
        "This device cannot vibrate; the clicks carry each step instead.",
        uk: "Цей пристрій не вібрує — кожен крок передають клацання."
    )
    static let sounds = Bilingual("Clicks on each step", uk: "Клацання на кожному кроці")

    static let sectionPrivacy = Bilingual("Privacy", uk: "Приватність")
    static let privacy = Bilingual(
        "No account. No analytics. Nothing you say, choose or show the camera ever leaves this device.",
        uk: "Без облікового запису. Без аналітики. Ніщо з того, що ви кажете, обираєте чи показуєте камері, не залишає цей пристрій."
    )
    static let reset = Bilingual("Reset to defaults", uk: "Скинути налаштування")
    static let resetConfirmTitle = Bilingual("Reset all settings?", uk: "Скинути всі налаштування?")
    static let resetConfirmMessage = Bilingual(
        "Scanning speed, switch timing and head control go back to their defaults. The language stays as it is.",
        uk: "Швидкість сканування, час перемикача й керування головою повернуться до типових значень. Мова залишиться та сама."
    )
    static let cancel = Bilingual("Cancel", uk: "Скасувати")

    static let secondsSuffix = Bilingual("s", uk: "с")
    /// The unit as VoiceOver should say it — "s" alone is read as a letter.
    static let secondsSpoken = Bilingual("seconds", uk: "секунди")
    static let degreesSpoken = Bilingual("degrees", uk: "градусів")
    static let ofNormalSpeed = Bilingual("of normal speed", uk: "від звичайної швидкості")
    static let degreesSuffix = Bilingual("°", uk: "°")

    // MARK: - Head try panel

    static let headTryTitle = Bilingual("No hands at all", uk: "Зовсім без рук")
    static let headTryBody = Bilingual(
        "Oleksandr can only move his head. Turn on head control, then turn your head to one side and hold it for a moment — that is a press.",
        uk: "Олександр може рухати лише головою. Увімкніть керування головою, а тоді поверніть голову вбік і затримайте на мить — це й є натискання."
    )
    static let headTryEnable = Bilingual("Turn on head control", uk: "Увімкнути керування головою")
    static let headTryDisable = Bilingual("Turn off head control", uk: "Вимкнути керування головою")
    static let headTrySkip = Bilingual("Skip", uk: "Пропустити")
    static let headTryContinue = Bilingual("Continue", uk: "Далі")
    static let headTrySuccess = Bilingual("That was a press — no hands.", uk: "Це було натискання — без рук.")
}
