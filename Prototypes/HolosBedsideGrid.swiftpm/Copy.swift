/// Every word Holos Bedside + Grid shows, in both languages.
///
/// The phrases a person SAYS live in `Vocabulary`; this file holds what the
/// screen says around them — the nurse, the goals, the closing card — so a
/// wording pass touches exactly one file. English apostrophes are plain;
/// Ukrainian uses ’ and «», as Ukrainian typography expects.
enum Copy {
    // MARK: - Step labels

    /// Small caps above every goal, so a judge always knows where they are
    /// in the three minutes.
    static let step1 = Bilingual("Step 1 of 4 · Feel the problem", uk: "Крок 1 з 4 · Відчуйте проблему")
    static let step2 = Bilingual("Step 2 of 4 · One switch, a whole conversation", uk: "Крок 2 з 4 · Один перемикач — ціла розмова")
    static let step3 = Bilingual("Step 3 of 4 · When the word won't come", uk: "Крок 3 з 4 · Коли слова не йдуть")
    static let step4 = Bilingual("Step 4 of 4 · Hear it in Ukrainian", uk: "Крок 4 з 4 · Почуйте українською")

    // MARK: - Step 1: the problem

    /// Second person on purpose: the judge is not watching Mykola, they ARE
    /// him for twenty seconds.
    static let problemSetup = Bilingual(
        "Imagine a stroke has taken your words. You understand everything, but you cannot speak, and your right hand will not move. You have one button: tap anywhere, or press Space.",
        uk: "Уявіть, що інсульт забрав у вас слова. Ви все розумієте, але не можете говорити, а права рука не рухається. У вас є одна кнопка: торкніться будь-де або натисніть пробіл."
    )
    static let yourTurn = Bilingual("Your turn", uk: "Ваша черга")
    static let replyEmpty = Bilingual(
        "Your answer would go here, if there were any way to give one.",
        uk: "Тут була б ваша відповідь, якби її було як дати."
    )
    /// Shown after a press that cannot do anything. Plain fact, no drama:
    /// the silence does the work.
    static let pressedInVain = Bilingual("You pressed. There is nothing to choose.", uk: "Ви натиснули, але обирати немає з чого.")

    static let nurseGreeting = Bilingual("Good morning! How are you feeling?", uk: "Доброго ранку! Як ви почуваєтеся?")
    static let nurseWaiting = Bilingual("…", uk: "…")
    /// What VoiceOver reads for the "…" bubble, which on its own is read as
    /// punctuation.
    static let nurseWaitingSpoken = Bilingual("The nurse waits.", uk: "Медсестра чекає.")
    static let nurseTakeTime = Bilingual("Take your time.", uk: "Не поспішайте.")
    /// Gentle, not cruel: she is busy, not unkind. That is the real problem.
    static let nurseLater = Bilingual("I'll come back later, then.", uk: "Тоді я зайду пізніше.")
    static let noteNurseLeft = Bilingual("She leaves. You never got to answer.", uk: "Вона виходить. Ви так і не змогли відповісти.")

    static let cardTitle = Bilingual("Holos gives your answer a voice.", uk: "Holos дає вашій відповіді голос.")
    static let cardBody = Bilingual(
        "When someone asks you something, Holos offers the few answers that fit. If yours isn't there, the whole board is one press away. Press once when the right one lights up, and Holos says it aloud.",
        uk: "Коли вас про щось питають, Holos пропонує кілька відповідей, що пасують. Якщо вашої серед них немає, уся дошка — за одне натискання. Натисніть один раз, коли засвітиться потрібна, — і Holos скаже її вголос."
    )
    static let pressToAnswer = Bilingual("Press to answer", uk: "Натисніть, щоб відповісти")
    static let pressToAnswerHint = Bilingual(
        "Starts the conversation again, this time with Holos.",
        uk: "Починає розмову знову — цього разу з Holos."
    )

    // MARK: - The nurse (on-screen text only; she is never spoken aloud)

    static let noteTenMinutes = Bilingual("Ten minutes later", uk: "Через десять хвилин")
    static let noteLittleLater = Bilingual("A little later", uk: "Трохи згодом")

    static let nurseBack = Bilingual("I'm back. How are you feeling now?", uk: "Я повернулася. Як ви почуваєтеся зараз?")
    static let nurseSorry = Bilingual("I'm sorry.", uk: "Мені дуже шкода.")
    static let nurseThanksForTelling = Bilingual("Thank you for telling me.", uk: "Дякую, що сказали.")
    static let nurseWhereHurts = Bilingual("Where does it hurt?", uk: "Де болить?")
    /// Used when the person did not say "in pain": the nurse still checks,
    /// without pretending she heard something she did not.
    static let nurseAnythingHurt = Bilingual("Does anything hurt? Show me where.", uk: "Щось болить? Покажіть, де саме.")
    static let nurseYourHead = Bilingual("Your head. Thank you for showing me.", uk: "Голова. Дякую, що показали.")
    static let nurseThanks = Bilingual("Thank you.", uk: "Дякую.")
    static let nurseHowBad = Bilingual("How bad is it?", uk: "Наскільки сильно болить?")
    /// After an answer that was not about where it hurts: she still asks,
    /// but does not take for granted that something does.
    static let nurseHowBadIfAny = Bilingual("If anything hurts, how bad is it?", uk: "Якщо щось болить, то наскільки сильно?")
    static let nurseMedicine = Bilingual("I'll bring your medicine now.", uk: "Я зараз принесу ваші ліки.")
    /// A generic reply. Like `nurseThanksAllRight` and `nurseHearYou`, it must
    /// fit every answer that can reach it — "No", "Not sure", "Thank you" and
    /// the "Something else" words too — so it acknowledges, and never
    /// promises what nobody asked for.
    static let nurseWillTellDoctor = Bilingual("Thank you. I'll let the doctor know.", uk: "Дякую. Я скажу лікареві.")
    static let nurseAnythingElse = Bilingual("Do you need anything else?", uk: "Вам ще щось потрібно?")
    static let nurseComingUp = Bilingual("Coming right up.", uk: "Зараз принесу.")
    static let nurseThanksAllRight = Bilingual("All right. Thank you for telling me.", uk: "Добре. Дякую, що сказали.")
    static let nurseTellMe = Bilingual("Is there anything you want to tell me?", uk: "Ви хочете мені щось сказати?")
    static let nurseCallWife = Bilingual("Of course. I'll call your wife right away.", uk: "Звісно. Я одразу подзвоню вашій дружині.")
    /// Feminine «почула»: the nurse is a woman («Я повернулася»).
    static let nurseHearYou = Bilingual("All right. I hear you.", uk: "Добре. Я вас почула.")

    // MARK: - Goals (the banner above the board)

    static let goalPain = Bilingual("Tell the nurse you're in pain.", uk: "Скажіть медсестрі, що вам боляче.")
    static let goalPainDetail = Bilingual(
        "Any answer works: the nurse will follow you.",
        uk: "Підійде будь-яка відповідь: медсестра підлаштується."
    )
    static let goalHead = Bilingual("Show her where: your head.", uk: "Покажіть, де саме: голова.")
    static let goalHeadDetail = Bilingual(
        "The board changed with her question. Now it is a body.",
        uk: "Дошка змінилася разом із питанням. Тепер це тіло."
    )
    static let goalALot = Bilingual("Tell her how bad: a lot.", uk: "Скажіть, наскільки: сильно.")
    static let goalALotDetail = Bilingual(
        "Four answers in order, with faces. Nothing to spell.",
        uk: "Чотири відповіді по порядку, з обличчями. Нічого не треба писати."
    )
    static let goalWater = Bilingual("Ask for water.", uk: "Попросіть води.")
    static let goalWife = Bilingual("Ask her to call your wife.", uk: "Попросіть її подзвонити вашій дружині.")
    /// Shorter than Bedside's: the whole board's own guide lines take over
    /// once it is open, and step 3 has a few more presses to spend.
    static let goalWifeDetail = Bilingual(
        "With aphasia the word \"wife\" may not come, even when you know exactly who you mean. Choose Something else: the whole board opens, and Family offers the word.",
        uk: "За афазії слово «дружина» може не згадатися, хоч ви й точно знаєте, кого маєте на увазі. Оберіть «Щось інше» — відкриється вся дошка, і тема «Родина» підкаже слово."
    )
    /// The same goal for a phone screen, where the banner has two lines.
    static let goalWifeDetailShort = Bilingual(
        "With aphasia the word \"wife\" may not come. Choose Something else: the whole board opens.",
        uk: "За афазії слово «дружина» може не згадатися. Оберіть «Щось інше» — відкриється вся дошка."
    )
    /// While the optional head-turn panel is up, the banner says only this:
    /// the turn's own goal is done and would point at a board under the panel.
    static let goalHeadTry = Bilingual(
        "Optional: try a turn of the head, or skip.",
        uk: "За бажанням: спробуйте повернути голову або пропустіть."
    )
    /// While the whole board is open, the banner's one line follows the
    /// guide tag: the topic, then the word, then Speak. On the board a press
    /// first picks a ROW, so the scanning lines name the row first.
    static func guideTopic(_ topic: Topic, scanning: Bool) -> Bilingual {
        let name = topic.name
        return scanning
            ? Bilingual("Open the \(name.en) board: the topics row, then \(name.en).", uk: "Відкрийте тему «\(name.uk)»: ряд тем, а потім «\(name.uk)».")
            : Bilingual("Tap \(name.en) in the topics row.", uk: "Торкніться «\(name.uk)» у ряду тем.")
    }
    static func guideCell(_ phrase: Phrase, scanning: Bool) -> Bilingual {
        let label = phrase.label
        return scanning
            ? Bilingual(
                "There it is: the word you could not find. Its row, then \(label.en).",
                uk: "Ось воно — слово, якого ви не могли знайти. Його ряд, а потім «\(label.uk)».",
                ukFeminine: label.ukFeminine.map { "Ось воно — слово, якого ви не могли знайти. Його ряд, а потім «\($0)»." }
            )
            : Bilingual(
                "There it is: the word you could not find. Tap \(label.en).",
                uk: "Ось воно — слово, якого ви не могли знайти. Торкніться «\(label.uk)».",
                ukFeminine: label.ukFeminine.map { "Ось воно — слово, якого ви не могли знайти. Торкніться «\($0)»." }
            )
    }
    static func guideSpeak(_ phrases: [Phrase], scanning: Bool) -> Bilingual {
        let en = phrases.map(\.label.en).joined(separator: " and ")
        let uk = phrases.map { "«\($0.label.uk)»" }.joined(separator: " і ")
        return scanning
            ? Bilingual("\(en) is in your message. Now the message row, then Speak.", uk: "\(uk) — у вашому повідомленні. Тепер ряд повідомлення, а потім «Сказати».")
            : Bilingual("\(en) is in your message. Now tap Speak.", uk: "\(uk) — у вашому повідомленні. Тепер торкніться «Сказати».")
    }
    static let guideBackToAnswers = Bilingual(
        "That answer is with the answers to her question. Go back to them.",
        uk: "Ця відповідь — серед відповідей на її питання. Поверніться до них."
    )
    static let howScan = Bilingual("Press when the marked answer lights up.", uk: "Натисніть, коли засвітиться позначена відповідь.")
    static let howTouch = Bilingual("Tap the marked answer.", uk: "Торкніться позначеної відповіді.")
    /// "Show me" is the brief's name for the way out. The Ukrainian says what
    /// the button does (it answers), in the infinitive buttons use, so it is
    /// not read as the nurse's polite «Покажіть» to the person.
    static let showMe = Bilingual("Show me", uk: "Відповісти за мене")
    static let showMeHint = Bilingual("Chooses the suggested answer for you.", uk: "Обирає підказану відповідь за вас.")
    static let guideMarker = Bilingual("This one", uk: "Ось ця")
    static let suggested = Bilingual("Suggested answer", uk: "Підказана відповідь")
    static let nurseAnswering = Bilingual("The nurse is answering…", uk: "Медсестра відповідає…")

    // MARK: - Chat roles (accessibility)

    static let roleNurse = Bilingual("Nurse", uk: "Медсестра")
    static let rolePartner = Bilingual("Partner", uk: "Співрозмовник")
    static let roleYou = Bilingual("You said", uk: "Ви сказали")
    static let transcriptLabel = Bilingual("Conversation", uk: "Розмова")
    static let questionLabel = Bilingual("Question", uk: "Питання")

    // MARK: - Questions (the partner's question cards)

    static let qFeeling = Bilingual("How are you feeling?", uk: "Як ви почуваєтеся?")
    static let qWhere = Bilingual("Where does it hurt?", uk: "Де болить?")
    static let qHowBad = Bilingual("How bad is it?", uk: "Наскільки сильно болить?")
    static let qNeeds = Bilingual("Do you need anything?", uk: "Вам щось потрібно?")
    static let qCall = Bilingual("Who should we call?", uk: "Кому нам подзвонити?")
    static let qRest = Bilingual("Do you want to rest?", uk: "Хочете відпочити?")
    static let qTell = Bilingual("Is there anything you want to tell me?", uk: "Ви хочете мені щось сказати?")

    // MARK: - The whole board (Holos Grid's)

    static let somethingElseHint = Bilingual(
        "Opens the whole board: every topic, urgent phrases and a message to build.",
        uk: "Відкриває всю дошку: усі теми, термінові фрази й повідомлення, яке можна скласти."
    )
    /// Said to VoiceOver when "Something else" opens the whole board.
    static let wholeBoardOpened = Bilingual("The whole board is open.", uk: "Відкрито всю дошку.")
    static let backToAnswers = Bilingual("Back to the answers", uk: "Назад до відповідей")
    static let backToAnswersHint = Bilingual(
        "Closes the whole board and shows the answers to the question again.",
        uk: "Закриває всю дошку й знову показує відповіді на питання."
    )
    /// The strip above the whole board when nobody is asking.
    static let boardHome = Bilingual("Nobody is asking. Say anything.", uk: "Ніхто не питає. Скажіть що завгодно.")
    static let youSaid = Bilingual("You said", uk: "Ви сказали")
    static let quickRow = Bilingual("Quick phrases", uk: "Швидкі фрази")
    static let topicsRow = Bilingual("Topics", uk: "Теми")
    static func topicRow(_ topic: Topic, _ number: Int) -> Bilingual {
        Bilingual("\(topic.name.en), row \(number)", uk: "\(topic.name.uk), ряд \(number)")
    }
    static let topicHint = Bilingual("Shows this topic's words.", uk: "Показує слова цієї теми.")
    static let topicNeeds = Bilingual("Needs", uk: "Потреби")
    static let topicPain = Bilingual("Pain & body", uk: "Біль і тіло")
    /// «Лікування», not «Ліки»: the topic is treatment; «Ліки» is its first cell.
    static let topicMedicine = Bilingual("Medicine", uk: "Лікування")
    static let topicFamily = Bilingual("Family", uk: "Родина")
    static let topicFeelings = Bilingual("Feelings", uk: "Почуття")
    /// Not «Розмова»: that is already the transcript's name for VoiceOver.
    static let topicTalk = Bilingual("Talk", uk: "Спілкування")

    // MARK: - Free conversation (after the tour)

    static let askHeader = Bilingual(
        "For the partner: tap a question to ask it",
        uk: "Для співрозмовника: торкніться питання, щоб його поставити"
    )
    static let askHint = Bilingual(
        "Asks this question. The board changes to the answers that fit.",
        uk: "Ставить це питання. Дошка покаже відповіді, що пасують."
    )
    static let newConversation = Bilingual("New conversation", uk: "Нова розмова")
    static let newConversationHint = Bilingual("Clears the conversation.", uk: "Очищає розмову.")
    /// The whole board is home after the story, so nobody has to ask first.
    static let freeNote = Bilingual(
        "Free conversation. Nobody has to ask first: the whole board is here. A partner can also tap a question above, and the board offers the answers that fit.",
        uk: "Вільна розмова. Ніхто не мусить питати першим — уся дошка тут. Співрозмовник також може торкнутися питання вгорі, і дошка запропонує відповіді, що пасують."
    )

    // MARK: - Step 4: replay in Ukrainian

    static let replayTitle = Bilingual("The same conversation, in Ukrainian.", uk: "Та сама розмова — українською.")
    static let replayBody = Bilingual(
        "Every answer was kept as meaning, not as typed text, so the whole conversation can be said again in Ukrainian: the language of the people Holos is for.",
        uk: "Кожну відповідь збережено як зміст, а не як набраний текст, тож усю розмову можна сказати ще раз українською — мовою людей, для яких створено Holos."
    )
    static let replaySpeaking = Bilingual("Saying your answers in Ukrainian…", uk: "Промовляємо ваші відповіді українською…")
    static let replayDone = Bilingual("That was your whole conversation, in Ukrainian.", uk: "Це була вся ваша розмова українською.")
    /// Without a Ukrainian voice the answers are spoken in English, so the
    /// status must not claim Ukrainian speech; the voice notice says how to
    /// add the voice.
    static let replayShownOnly = Bilingual("Your answers again, shown in Ukrainian…", uk: "Ваші відповіді ще раз — українською на екрані…")
    static let replayDoneShownOnly = Bilingual(
        "That was your whole conversation, shown in Ukrainian.",
        uk: "Це була вся ваша розмова — українською на екрані."
    )
    static let replayNothing = Bilingual(
        "You gave no answers this time, so there is nothing to replay. That's fine.",
        uk: "Цього разу відповідей не було, тож повторювати нічого. Нічого страшного."
    )
    static let continueLabel = Bilingual("Continue", uk: "Далі")
    static let continueHint = Bilingual("Goes on to the last screen.", uk: "Переходить до останнього екрана.")

    // MARK: - Closing

    /// "Far more", not "every word": aphasia often reaches understanding too,
    /// and this card says a few lines later that it can take reading.
    static let closingTitle = Bilingual(
        "For people who understand far more than they can say.",
        uk: "Для тих, хто розуміє значно більше, ніж може сказати."
    )
    static let closingWho = Bilingual(
        "Rehabilitation centres in Ukraine treat many service members recovering from brain injuries and strokes who struggle to communicate, often through aphasia or dysarthria. Aphasia can take reading and spelling as well as speech, so a keyboard is not enough.",
        uk: "Реабілітаційні центри в Україні лікують багатьох військових після черепно-мозкових травм та інсультів, яким важко спілкуватися, — часто через афазію чи дизартрію. Афазія може забрати не лише мовлення, а й читання та письмо, тож клавіатури замало."
    )
    static let closingHow = Bilingual(
        "Holos starts from the partner's question and offers only the answers that fit, so nobody has to find a word from nothing. When the answer isn't there, or nobody is asking, the whole board is one press away. One switch is enough: a tap, a key, a controller button or a turn of the head.",
        uk: "Holos зважає на питання співрозмовника й пропонує лише ті відповіді, що пасують, — тож нікому не доводиться шукати слово з нуля. Коли потрібної відповіді немає або ніхто не питає, уся дошка — за одне натискання. Досить одного перемикача: дотику, клавіші, кнопки контролера чи повороту голови."
    )
    static let closingFree = Bilingual(
        "Free, because a voice should not be a subscription. Private: no account, no analytics, nothing leaves this device. Open source, so speech therapists can check it, translate it and keep it alive.",
        uk: "Безплатний, бо голос не має бути підпискою. Поважає приватність: без облікового запису, без аналітики, ніщо не залишає цей пристрій. З відкритим кодом, щоб логопеди могли його перевірити, перекласти й підтримувати."
    )
    static let closingSource = Bilingual(
        "On rehabilitation in Ukraine: Talk! (Говори!) NGO.",
        uk: "Про реабілітацію в Україні: ГО «Говори!»."
    )
    static let keepTalking = Bilingual("Keep talking", uk: "Говорити далі")
    static let keepTalkingHint = Bilingual("Opens the board for a free conversation.", uk: "Відкриває дошку для вільної розмови.")
    static let startAgain = Bilingual("Start again", uk: "Почати знову")
    static let startAgainHint = Bilingual("Restarts the three-minute story.", uk: "Починає трихвилинну історію спочатку.")
}
