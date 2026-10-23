/// Every string Holos Compass shows, in both languages.
///
/// The words a person *says* live in `Vocabulary`; these are the words the
/// app says *to* them. Kept in one file so a wording pass — or a therapist's
/// review — touches exactly one place. Shared strings (Speak, Go back,
/// Settings, the head-switch states) come from `CoreCopy`.
enum Copy {
    // MARK: - App chrome

    enum App {
        static let name = Bilingual("Holos", uk: "Holos")
        static let subtitle = Bilingual("Compass", uk: "Компас")

        static func stepOf(_ number: Int) -> Bilingual {
            Bilingual("Step \(number) of 4", uk: "Крок \(number) з 4")
        }

        static let continueLabel = Bilingual("Continue", uk: "Далі")
        static let continueHint = Bilingual("Goes to the next part.", uk: "Переходить до наступної частини.")
        /// Under a narrative screen, so the judge knows any press works.
        static let pressAnywhere = Bilingual("Press anywhere to continue", uk: "Натисніть будь-де, щоб продовжити")
    }

    // MARK: - Step titles

    enum Steps {
        static let problem = Bilingual("The problem", uk: "Проблема")
        static let compose = Bilingual("Four choices, any sentence", uk: "Чотири варіанти — будь-яке речення")
        static let head = Bilingual("Point with your head", uk: "Вказуйте головою")
        static let ukrainian = Bilingual("Hear it in Ukrainian", uk: "Почуйте українською")
        static let closing = Bilingual("Who it is for", uk: "Для кого це")
        static let free = Bilingual("Talk", uk: "Розмова")
    }

    // MARK: - Step 1: the problem

    /// The nurse speaks in a bubble only. The synthesizer is the person's
    /// voice and never anyone else's.
    enum Problem {
        static let nurseName = Bilingual("Nurse", uk: "Медсестра")
        static let nurseQuestion = Bilingual("How are you feeling?", uk: "Як ви почуваєтеся?")
        static let youName = Bilingual("You", uk: "Ви")

        static let title = Bilingual("You are Oleksandr", uk: "Ви — Олександр")
        static let body = Bilingual(
            "Oleksandr, 41, is in early rehabilitation after a brain injury. He understands every word. He cannot speak, write or point with his hands. What he still has is his head — and one movement.",
            uk: "Олександрові 41 рік, він на ранньому етапі реабілітації після травми мозку. Він розуміє кожне слово, але не може говорити, писати чи показувати рукою. У нього лишилися голова — і один рух."
        )
        /// Personas are illustrations; the fact behind them is not.
        static let example = Bilingual(
            "Oleksandr is an example, not a real patient. But rehabilitation centres in Ukraine treat many service members recovering from brain injuries and strokes who struggle to communicate.",
            uk: "Олександр — приклад, а не справжній пацієнт. Але в реабілітаційних центрах України лікується багато військових, яким після травм мозку чи інсультів важко спілкуватися."
        )
        static let prompt = Bilingual(
            "The nurse is waiting. Your one movement is this button. Answer her.",
            uk: "Медсестра чекає. Ваш єдиний рух — ця кнопка. Дайте їй відповідь."
        )
        static let button = Bilingual("Press", uk: "Натиснути")
        static let buttonHint = Bilingual("Your one movement.", uk: "Ваш єдиний рух.")
        static let nothing = Bilingual(
            "Nothing. One press is a sound, not a sentence.",
            uk: "Нічого. Одне натискання — це звук, а не речення."
        )
        static let turn = Bilingual(
            "But a press that picks one of four, again and again, can say almost anything. That is the compass.",
            uk: "Але натискання, яке щоразу обирає один із чотирьох варіантів, може сказати майже все. Це і є компас."
        )
        static let pressAgain = Bilingual("Press again to continue", uk: "Натисніть ще раз, щоб продовжити")
    }

    // MARK: - Step 2: four choices, any sentence

    enum Compose {
        static let goalTitle = Bilingual("Say this to the nurse", uk: "Скажіть це медсестрі")
        /// Names every stop of the ring, the buttons under the centre too,
        /// so nothing lights up unexplained.
        static let howToScan = Bilingual(
            "The light sweeps clockwise — up, right, down, left, the centre, then the buttons under it. Press when it reaches the choice you want. The marked choice shows the way.",
            uk: "Підсвітка йде за годинниковою стрілкою — вгору, праворуч, вниз, ліворуч, центр, а потім кнопки під ним. Натисніть, коли вона дійде до потрібного варіанта. Позначений варіант підказує шлях."
        )
        static let howToTouch = Bilingual(
            "Tap a choice. The marked one shows the way.",
            uk: "Торкніться варіанта. Позначений підказує шлях."
        )
        static let said = Bilingual("Said", uk: "Сказано")
        static let notYet = Bilingual("Not yet", uk: "Ще ні")
        static let stuck = Bilingual(
            "Taking a while? That is how it feels. You can move on whenever you like.",
            uk: "Довго? Саме так це й відчувається. Можна перейти далі будь-коли."
        )
        static let moveOn = Bilingual("Move on", uk: "Перейти далі")
        static let moveOnHint = Bilingual("Ends this part, even if the message isn't finished.", uk: "Завершує цю частину, навіть якщо повідомлення ще не готове.")
        static let doneTitle = Bilingual("You said it.", uk: "Ви це сказали.")
        static let doneGoal = Bilingual(
            "Two sentences, one button — and the path through the compass built each one.",
            uk: "Два речення, одна кнопка — і кожне склав шлях через компас."
        )
        static let doneOther = Bilingual(
            "You said what you chose to say. That is the whole point.",
            uk: "Ви сказали те, що вирішили сказати. У цьому й суть."
        )
        /// For a judge who moved on without saying anything: "You said it"
        /// would be untrue, and the slowness itself is the lesson.
        static let movedOnTitle = Bilingual("Moving on.", uk: "Рухаємося далі.")
        static let movedOnBody = Bilingual(
            "That is how slow one switch can feel — and why every press saved matters.",
            uk: "Ось наскільки повільним може бути один перемикач — і чому важливе кожне зекономлене натискання."
        )

        static func presses(_ count: Int) -> Bilingual {
            Bilingual(
                count == 1 ? "1 press" : "\(count) presses",
                uk: "Натискань: \(count)"
            )
        }
    }

    // MARK: - Step 3: point with your head

    enum Head {
        static let title = Bilingual("Or point with your head", uk: "Або вказуйте головою")
        static let body = Bilingual(
            "Four choices sit in four directions, so a head can point: up, right, down or left. Hold it there for a second to choose, then come back to the middle. No scanning, no waiting.",
            uk: "Чотири варіанти — це чотири напрямки, тож головою можна вказувати: вгору, праворуч, вниз чи ліворуч. Утримуйте голову так секунду, щоб обрати, а тоді поверніться до центру. Без сканування й очікування."
        )
        /// "Tip your head", not "look": the pointer reads the head's angle,
        /// and eyes raised alone never cross the threshold.
        static let tryIt = Bilingual(
            "Try it: turn on head pointing, then tip your head up and hold it there to say “Yes”.",
            uk: "Спробуйте: увімкніть вказування головою, а тоді підніміть голову й потримайте її так, щоб сказати «Так»."
        )
        static let optional = Bilingual(
            "Optional. The camera stays off unless you turn it on, and nothing is recorded.",
            uk: "Необов’язково. Камера не вмикається, доки ви її не ввімкнете, і нічого не записується."
        )
        static let enable = Bilingual("Turn on head pointing", uk: "Увімкнути вказування головою")
        static let disable = Bilingual("Turn off head pointing", uk: "Вимкнути вказування головою")
        static let swapLeftRight = Bilingual("Swap left and right", uk: "Поміняти лівий і правий бік")
        static let swapUpDown = Bilingual("Swap up and down", uk: "Поміняти верх і низ")
        static let swapHint = Bilingual(
            "If the light goes the wrong way, swap the directions.",
            uk: "Якщо підсвітка йде не в той бік, поміняйте напрямки місцями."
        )
        static let off = Bilingual("Head pointing is off.", uk: "Вказування головою вимкнено.")
        static let ready = Bilingual("Point with your head, then hold", uk: "Вкажіть головою й утримуйте положення")
        static let fallback = Bilingual(
            "No face in view, so the scan carries on meanwhile. Nothing is lost.",
            uk: "Обличчя не видно, тож тим часом працює сканування. Нічого не втрачено."
        )

        static func holding(_ direction: Direction) -> Bilingual {
            let name = Board.directionName(direction)
            return Bilingual("\(name.en) — hold to choose", uk: "\(name.uk) — утримуйте, щоб обрати")
        }

        static func success(_ label: Bilingual) -> Bilingual {
            Bilingual(
                "You chose “\(label.en)” with your head — no hands.",
                uk: "Ви обрали «\(label.uk)» головою — без рук."
            )
        }

        /// While pointing, the head picks among the four; the person's one
        /// other movement, if they have one, does the rest. Below home the
        /// head can also go back on its own, by resting in the middle.
        static let restBack = Bilingual(
            "To go back, rest your head in the middle — or press.",
            uk: "Щоб повернутися, потримайте голову в центрі — або натисніть."
        )
        static let restingBack = Bilingual("Resting in the middle — going back…", uk: "Голова в центрі — повертаємося назад…")
        static let pressSpeak = Bilingual("Your one press: speak the message", uk: "Ваше натискання: сказати повідомлення")
    }

    // MARK: - Step 4: hear it in Ukrainian

    enum Ukrainian {
        static let title = Bilingual("Hear it in Ukrainian", uk: "Почуйте українською")
        static let body = Bilingual(
            "Holos is made for Ukrainian hospitals. Every choice carries its Ukrainian sentence written out whole, with the grammar right for a man or a woman.",
            uk: "Holos створено для українських лікарень. Кожен варіант має своє українське речення, написане повністю, з правильною граматикою для чоловіка чи жінки."
        )
        static let hear = Bilingual("Hear it in Ukrainian", uk: "Почути українською")
        static let hearAgain = Bilingual("Hear it again", uk: "Почути ще раз")
        static let hearHint = Bilingual("Says the message aloud in Ukrainian.", uk: "Промовляє повідомлення українською.")
        /// Shown in English too: the judge it reassures may not read the
        /// Ukrainian, and the button it names now reads «Далі».
        static let switched = Bilingual(
            "The whole board is now in Ukrainian. The «Далі» (Continue) button brings English back.",
            uk: "Уся дошка тепер українською. «Далі» поверне англійську."
        )
    }

    // MARK: - Closing

    enum Closing {
        static let title = Bilingual("Holos means “voice”.", uk: "Holos — від українського «голос».")
        static let who = Bilingual(
            "For Ukrainian adults who lost their speech to a stroke, a brain injury or war trauma — and for the families, carers and speech therapists around them.",
            uk: "Для дорослих українців, які втратили мовлення через інсульт, травму мозку чи воєнну травму, — і для їхніх родин, доглядальників і логопедів."
        )
        /// The product's core reason, which the tour itself shows through
        /// Oleksandr's head rather than through an aphasia board.
        static let aphasia = Bilingual(
            "Many have aphasia, which can take reading and spelling as well as speech — so a keyboard is not enough. The compass offers the words; nobody has to recall them.",
            uk: "Багато хто має афазію, яка може забрати не лише мовлення, а й читання та письмо, — тож клавіатури недостатньо. Компас пропонує слова: їх не треба пригадувати."
        )
        static let whyCompass = Bilingual(
            "Four choices at a time: big enough to see from a bed, few enough to hold in mind, and in four directions — so a head can point.",
            uk: "Лише чотири варіанти за раз: їх видно з ліжка, їх легко втримати в пам’яті, і вони розташовані в чотирьох напрямках — тож можна вказувати головою."
        )
        static let free = Bilingual(
            "Free, because a voice should not be a subscription. Private by design: no account, no analytics, nothing leaves the device.",
            uk: "Безкоштовний, бо голос не має бути підпискою. Приватний за задумом: без облікового запису, без аналітики, ніщо не залишає пристрій."
        )
        static let open = Bilingual(
            "Open source, so anyone can check it, translate it and keep it alive.",
            uk: "З відкритим кодом, щоб кожен міг перевірити його, перекласти й підтримувати."
        )
        static let watch = Bilingual(
            "Four choices also fit an Apple Watch face — the next place this voice should go.",
            uk: "Чотири варіанти вміщаються й на циферблаті Apple Watch — і саме туди цей голос має потрапити далі."
        )
        static let keepTalking = Bilingual("Keep talking", uk: "Говорити далі")
        static let keepTalkingHint = Bilingual("Opens the whole compass to use freely.", uk: "Відкриває весь компас для вільного користування.")
        static let startAgain = Bilingual("Start again", uk: "Почати знову")
        static let startAgainHint = Bilingual("Goes back to the beginning.", uk: "Повертає на початок.")
    }

    // MARK: - The board itself

    enum Board {
        static let opensHint = Bilingual("Opens four more choices.", uk: "Відкриває ще чотири варіанти.")
        static let suggested = Bilingual("Suggested next", uk: "Підказка: наступний крок")
        /// The guide marker on the next petal. Short: it sits on the petal.
        static let next = Bilingual("Next", uk: "Сюди")
        static let speaking = Bilingual("Speaking…", uk: "Звучить…")
        static let paused = Bilingual("Resting. Press to start again.", uk: "Пауза. Натисніть, щоб почати знову.")
        /// Not "Start over": the tour's own "Start again" restarts
        /// everything and clears the message, and the two must never be
        /// confused. This only goes back to the first four, matching the
        /// "Start" crumb in the centre.
        static let backToStart = Bilingual("Back to start", uk: "На початок")
        static let backToStartHint = Bilingual(
            "Goes straight back to the first four choices. Your message stays.",
            uk: "Повертає одразу до перших чотирьох варіантів. Повідомлення залишається."
        )
        static let headPointing = Bilingual("Head pointing", uk: "Вказування головою")
        static let headPointingHint = Bilingual(
            "Choose by pointing your head up, right, down or left. Uses the front camera; nothing is recorded.",
            uk: "Обирайте, вказуючи головою вгору, праворуч, вниз чи ліворуч. Працює з фронтальною камерою; нічого не записується."
        )

        static func directionName(_ direction: Direction) -> Bilingual {
            switch direction {
            case .north: Bilingual("Up", uk: "Вгору")
            case .east: Bilingual("Right", uk: "Праворуч")
            case .south: Bilingual("Down", uk: "Вниз")
            case .west: Bilingual("Left", uk: "Ліворуч")
            }
        }

        /// The scan stop that switches language names the language it goes
        /// TO, in that language — a Ukrainian reader looks for «Українська».
        static func switchTo(_ language: Language) -> Bilingual {
            Bilingual(language.nativeName, uk: language.nativeName)
        }

        /// The same stop as an auditory prompt. Only the board's current
        /// language is ever spoken (or English, when there is no Ukrainian
        /// voice), so each field names the target in a voice that can say it:
        /// an English voice must never be handed «Українська».
        static func switchToSpoken(_ target: Language) -> Bilingual {
            switch target {
            case .ukrainian: Bilingual("Switch to Ukrainian", uk: "Перейти на українську")
            case .english: Bilingual("Switch to English", uk: "Перейти на англійську")
            }
        }
    }
}
