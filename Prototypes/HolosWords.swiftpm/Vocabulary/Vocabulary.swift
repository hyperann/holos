import Foundation

/// Every sentence the board can say.
///
/// Six starters × eight fillers on the board, plus the sentences only Find
/// a word reaches. Each filler is a complete sentence in both languages —
/// see `SentenceFrame` for why nothing here is ever glued together. The
/// words are adult and hospital-shaped on purpose: medicine, a nurse, a
/// commander, a brother-in-arms. This is a board for grown-ups in rehab,
/// not a first-words board.
///
/// SF Symbols stand in for pictures; the real app swaps in ARASAAC
/// pictograms, which are drawn for exactly this use.
enum Vocabulary {
    static let frames: [SentenceFrame] = FrameID.allCases.map { Vocabulary.frame($0) }

    static func frame(_ id: FrameID) -> SentenceFrame {
        switch id {
        case .need: need
        case .feel: feel
        case .want: want
        case .call: call
        case .canYou: canYou
        case .whereIs: whereIs
        }
    }

    /// Any phrase by its id, on the board or not.
    static func phrase(id: String) -> Phrase? {
        for frame in frames {
            if let found = frame.fillers.first(where: { $0.id == id }) ?? frame.more.first(where: { $0.id == id }) {
                return found
            }
        }
        return nil
    }

    /// The sentence for a word found by describing it.
    ///
    /// The open starter wins when it can take the word ("Call my…" + wife →
    /// "Please call my wife."). When it cannot, the word's own home starter
    /// takes it, so a found word always lands in a correct sentence rather
    /// than being refused.
    static func resolve(_ concept: String, preferring preferred: FrameID, home: FrameID) -> (frame: FrameID, phrase: Phrase)? {
        if let phrase = frame(preferred).phrase(for: concept) {
            return (preferred, phrase)
        }
        if let phrase = frame(home).phrase(for: concept) {
            return (home, phrase)
        }
        return nil
    }

    /// What the Ukrainian step plays if the tour was skipped before
    /// anything was said: the tour's own two goals.
    static let tourExample: [Phrase] = [
        Phrase.makeID(.feel, "pain"),
        Phrase.makeID(.need, "medicine"),
        Phrase.makeID(.call, "wife"),
    ].compactMap { Vocabulary.phrase(id: $0) }

    // MARK: - I need…

    static let need = SentenceFrame(
        id: .need,
        starter: Bilingual("I need…", uk: "Мені потрібно…"),
        stem: Bilingual("I need", uk: "Мені потрібно"),
        symbol: "exclamationmark.bubble.fill",
        kind: .people,
        fillers: [
            .filler(.need, "medicine", Bilingual("Medicine", uk: "Ліки"),
                    says: Bilingual("I need medicine.", uk: "Мені потрібні ліки."),
                    symbol: "pills.fill", kind: .thing),
            .filler(.need, "water", Bilingual("Water", uk: "Вода"),
                    says: Bilingual("I need some water.", uk: "Мені потрібна вода."),
                    symbol: "drop.fill", kind: .thing),
            .filler(.need, "doctor", Bilingual("Doctor", uk: "Лікар"),
                    says: Bilingual("I need a doctor.", uk: "Мені потрібен лікар."),
                    symbol: "stethoscope", kind: .people),
            .filler(.need, "nurse", Bilingual("Nurse", uk: "Медсестра"),
                    says: Bilingual("I need a nurse.", uk: "Мені потрібна медсестра."),
                    symbol: "cross.case.fill", kind: .people),
            .filler(.need, "toilet", Bilingual("Toilet", uk: "Туалет"),
                    says: Bilingual("I need the toilet.", uk: "Мені потрібно в туалет."),
                    symbol: "toilet.fill", kind: .thing),
            .filler(.need, "help", Bilingual("Help", uk: "Допомога"),
                    says: Bilingual("I need help.", uk: "Мені потрібна допомога."),
                    symbol: "hand.raised.fill", kind: .urgent),
            .filler(.need, "blanket", Bilingual("Blanket", uk: "Ковдра"),
                    says: Bilingual("I need a blanket.", uk: "Мені потрібна ковдра."),
                    symbol: "bed.double.fill", kind: .thing),
            .filler(.need, "glasses", Bilingual("Glasses", uk: "Окуляри"),
                    says: Bilingual("I need my glasses.", uk: "Мені потрібні мої окуляри."),
                    symbol: "eyeglasses", kind: .thing),
        ],
        more: [
            .filler(.need, "speechTherapist", Bilingual("Speech therapist", uk: "Логопед"),
                    says: Bilingual("I need my speech therapist.", uk: "Мені потрібен мій логопед."),
                    symbol: "bubble.left.and.bubble.right.fill", kind: .people),
            .filler(.need, "physio", Bilingual("Physio", uk: "Фізичний терапевт"),
                    says: Bilingual("I need my physio.", uk: "Мені потрібен мій фізичний терапевт."),
                    symbol: "figure.walk", kind: .people),
        ]
    )

    // MARK: - I feel…

    static let feel = SentenceFrame(
        id: .feel,
        starter: Bilingual("I feel…", uk: "Я почуваюся…"),
        stem: Bilingual("I feel", uk: "Я почуваюся"),
        symbol: "heart.fill",
        kind: .people,
        fillers: [
            .filler(.feel, "pain", Bilingual("Pain", uk: "Біль"),
                    says: Bilingual("I feel pain.", uk: "Мені боляче."),
                    symbol: "bandage.fill", kind: .urgent),
            .filler(.feel, "tired", Bilingual("Tired", uk: "Втомлений", ukFeminine: "Втомлена"),
                    says: Bilingual("I feel tired.", uk: "Я втомився.", ukFeminine: "Я втомилася."),
                    symbol: "moon.zzz.fill", kind: .describing),
            .filler(.feel, "cold", Bilingual("Cold", uk: "Холодно"),
                    says: Bilingual("I feel cold.", uk: "Мені холодно."),
                    symbol: "thermometer.snowflake", kind: .describing),
            .filler(.feel, "hot", Bilingual("Hot", uk: "Жарко"),
                    says: Bilingual("I feel hot.", uk: "Мені жарко."),
                    symbol: "thermometer.sun.fill", kind: .describing),
            .filler(.feel, "sick", Bilingual("Sick", uk: "Нудота"),
                    says: Bilingual("I feel sick.", uk: "Мене нудить."),
                    symbol: "face.dashed", kind: .describing),
            .filler(.feel, "scared", Bilingual("Scared", uk: "Страшно"),
                    says: Bilingual("I feel scared.", uk: "Мені страшно."),
                    symbol: "exclamationmark.triangle.fill", kind: .describing),
            .filler(.feel, "sad", Bilingual("Sad", uk: "Сумно"),
                    says: Bilingual("I feel sad.", uk: "Мені сумно."),
                    symbol: "cloud.rain.fill", kind: .describing),
            .filler(.feel, "better", Bilingual("Better", uk: "Краще"),
                    says: Bilingual("I feel better.", uk: "Мені краще."),
                    symbol: "sun.max.fill", kind: .describing),
        ],
        more: [
            .filler(.feel, "dizzy", Bilingual("Dizzy", uk: "Запаморочення"),
                    says: Bilingual("I feel dizzy.", uk: "У мене паморочиться голова."),
                    symbol: "brain.head.profile", kind: .describing),
            .filler(.feel, "bored", Bilingual("Bored", uk: "Нудно"),
                    says: Bilingual("I feel bored.", uk: "Мені нудно."),
                    symbol: "hourglass", kind: .describing),
        ]
    )

    // MARK: - I want…

    static let want = SentenceFrame(
        id: .want,
        starter: Bilingual("I want…", uk: "Я хочу…"),
        stem: Bilingual("I want", uk: "Я хочу"),
        symbol: "star.fill",
        kind: .people,
        fillers: [
            .filler(.want, "sitUp", Bilingual("Sit up", uk: "Сісти"),
                    says: Bilingual("I want to sit up.", uk: "Я хочу сісти."),
                    symbol: "chair.fill", kind: .action),
            .filler(.want, "lieDown", Bilingual("Lie down", uk: "Лягти"),
                    says: Bilingual("I want to lie down.", uk: "Я хочу лягти."),
                    symbol: "bed.double.fill", kind: .action),
            .filler(.want, "walk", Bilingual("Walk", uk: "Пройтися"),
                    says: Bilingual("I want to go for a walk.", uk: "Я хочу пройтися."),
                    symbol: "figure.walk", kind: .action),
            .filler(.want, "sleep", Bilingual("Sleep", uk: "Спати"),
                    says: Bilingual("I want to sleep.", uk: "Я хочу спати."),
                    symbol: "moon.fill", kind: .action),
            .filler(.want, "food", Bilingual("Eat", uk: "Їсти"),
                    says: Bilingual("I want something to eat.", uk: "Я хочу їсти."),
                    symbol: "fork.knife", kind: .action),
            .filler(.want, "drink", Bilingual("Drink", uk: "Пити"),
                    says: Bilingual("I want something to drink.", uk: "Я хочу пити."),
                    symbol: "cup.and.saucer.fill", kind: .action),
            .filler(.want, "home", Bilingual("Home", uk: "Додому"),
                    says: Bilingual("I want to go home.", uk: "Я хочу додому."),
                    symbol: "house.fill", kind: .thing),
            .filler(.want, "tv", Bilingual("TV", uk: "Телевізор"),
                    says: Bilingual("I want to watch TV.", uk: "Я хочу подивитися телевізор."),
                    symbol: "tv.fill", kind: .thing),
        ],
        more: [
            .filler(.want, "garden", Bilingual("Garden", uk: "Сад"),
                    says: Bilingual("I want to go out into the garden.", uk: "Я хочу вийти в сад."),
                    symbol: "tree.fill", kind: .thing),
            .filler(.want, "shower", Bilingual("Shower", uk: "Душ"),
                    says: Bilingual("I want a shower.", uk: "Я хочу прийняти душ."),
                    symbol: "shower.fill", kind: .thing),
            .filler(.want, "wash", Bilingual("Wash", uk: "Помитися"),
                    says: Bilingual("I want to wash.", uk: "Я хочу помитися."),
                    symbol: "bathtub.fill", kind: .action),
            .filler(.want, "tea", Bilingual("Tea", uk: "Чай"),
                    says: Bilingual("I want some tea.", uk: "Я хочу чаю."),
                    symbol: "mug.fill", kind: .thing),
        ]
    )

    // MARK: - Call my…

    // English "call" is two Ukrainian verbs: «подзвонити» (on the phone)
    // and «покликати» (fetch them here). Family is phoned; staff on the
    // ward are fetched — one more thing a glued sentence would get wrong.
    static let call = SentenceFrame(
        id: .call,
        starter: Bilingual("Call my…", uk: "Подзвоніть…"),
        stem: Bilingual("Call my", uk: "Подзвоніть"),
        symbol: "phone.fill",
        kind: .people,
        fillers: [
            .filler(.call, "mum", Bilingual("Mum", uk: "Мама"),
                    says: Bilingual("Please call my mum.", uk: "Подзвоніть, будь ласка, моїй мамі."),
                    symbol: "figure.arms.open", kind: .people),
            .filler(.call, "dad", Bilingual("Dad", uk: "Тато"),
                    says: Bilingual("Please call my dad.", uk: "Подзвоніть, будь ласка, моєму татові."),
                    symbol: "figure.stand", kind: .people),
            .filler(.call, "son", Bilingual("Son", uk: "Син"),
                    says: Bilingual("Please call my son.", uk: "Подзвоніть, будь ласка, моєму синові."),
                    symbol: "figure.walk", kind: .people),
            .filler(.call, "daughter", Bilingual("Daughter", uk: "Донька"),
                    says: Bilingual("Please call my daughter.", uk: "Подзвоніть, будь ласка, моїй доньці."),
                    symbol: "figure.wave", kind: .people),
            .filler(.call, "brother", Bilingual("Brother", uk: "Брат"),
                    says: Bilingual("Please call my brother.", uk: "Подзвоніть, будь ласка, моєму братові."),
                    symbol: "person.fill", kind: .people),
            .filler(.call, "sister", Bilingual("Sister", uk: "Сестра"),
                    says: Bilingual("Please call my sister.", uk: "Подзвоніть, будь ласка, моїй сестрі."),
                    symbol: "person.crop.circle.fill", kind: .people),
            .filler(.call, "friend", Bilingual("Friend", uk: "Друг"),
                    says: Bilingual("Please call my friend.", uk: "Подзвоніть, будь ласка, моєму другові."),
                    symbol: "hand.wave.fill", kind: .people),
            .filler(.call, "commander", Bilingual("Commander", uk: "Командир"),
                    says: Bilingual("Please call my commander.", uk: "Подзвоніть, будь ласка, моєму командирові."),
                    symbol: "star.fill", kind: .people),
        ],
        more: [
            .filler(.call, "wife", Bilingual("Wife", uk: "Дружина"),
                    says: Bilingual("Please call my wife.", uk: "Подзвоніть, будь ласка, моїй дружині."),
                    symbol: "heart.fill", kind: .people),
            .filler(.call, "husband", Bilingual("Husband", uk: "Чоловік"),
                    says: Bilingual("Please call my husband.", uk: "Подзвоніть, будь ласка, моєму чоловікові."),
                    symbol: "heart.fill", kind: .people),
            .filler(.call, "grandma", Bilingual("Grandma", uk: "Бабуся"),
                    says: Bilingual("Please call my grandma.", uk: "Подзвоніть, будь ласка, моїй бабусі."),
                    symbol: "person.fill", kind: .people),
            .filler(.call, "grandpa", Bilingual("Grandpa", uk: "Дідусь"),
                    says: Bilingual("Please call my grandpa.", uk: "Подзвоніть, будь ласка, моєму дідусеві."),
                    symbol: "person.fill", kind: .people),
            .filler(.call, "grandson", Bilingual("Grandson", uk: "Онук"),
                    says: Bilingual("Please call my grandson.", uk: "Подзвоніть, будь ласка, моєму онукові."),
                    symbol: "figure.and.child.holdinghands", kind: .people),
            .filler(.call, "granddaughter", Bilingual("Granddaughter", uk: "Онука"),
                    says: Bilingual("Please call my granddaughter.", uk: "Подзвоніть, будь ласка, моїй онуці."),
                    symbol: "figure.and.child.holdinghands", kind: .people),
            .filler(.call, "comrade", Bilingual("Brother-in-arms", uk: "Побратим"),
                    says: Bilingual("Please call my brother-in-arms.", uk: "Подзвоніть, будь ласка, моєму побратимові."),
                    symbol: "person.2.fill", kind: .people),
            .filler(.call, "neighbour", Bilingual("Neighbour", uk: "Сусід"),
                    says: Bilingual("Please call my neighbour.", uk: "Подзвоніть, будь ласка, моєму сусідові."),
                    symbol: "house.fill", kind: .people),
            .filler(.call, "doctor", Bilingual("Doctor", uk: "Лікар"),
                    says: Bilingual("Please call the doctor.", uk: "Покличте, будь ласка, лікаря."),
                    symbol: "stethoscope", kind: .people),
            .filler(.call, "nurse", Bilingual("Nurse", uk: "Медсестра"),
                    says: Bilingual("Please call the nurse.", uk: "Покличте, будь ласка, медсестру."),
                    symbol: "cross.case.fill", kind: .people),
        ]
    )

    // MARK: - Can you…

    // Ukrainian asks staff with a polite plural imperative and «будь ласка»
    // — «Відчиніть, будь ласка, вікно» — not a word-for-word "Can you…?".
    static let canYou = SentenceFrame(
        id: .canYou,
        starter: Bilingual("Can you…", uk: "Будь ласка…"),
        stem: Bilingual("Can you", uk: "Будь ласка,"),
        symbol: "questionmark.circle.fill",
        kind: .question,
        fillers: [
            .filler(.canYou, "sitUp", Bilingual("Sit up", uk: "Сісти"),
                    says: Bilingual("Can you help me sit up?", uk: "Допоможіть мені, будь ласка, сісти."),
                    symbol: "chair.fill", kind: .action),
            .filler(.canYou, "window", Bilingual("Window", uk: "Вікно"),
                    says: Bilingual("Can you open the window?", uk: "Відчиніть, будь ласка, вікно."),
                    symbol: "wind", kind: .thing),
            .filler(.canYou, "light", Bilingual("Light", uk: "Світло"),
                    says: Bilingual("Can you turn off the light?", uk: "Вимкніть, будь ласка, світло."),
                    symbol: "lightbulb.fill", kind: .thing),
            .filler(.canYou, "slowly", Bilingual("Slowly", uk: "Повільніше"),
                    says: Bilingual("Can you speak more slowly?", uk: "Говоріть, будь ласка, повільніше."),
                    symbol: "tortoise.fill", kind: .social),
            .filler(.canYou, "repeat", Bilingual("Again", uk: "Ще раз"),
                    says: Bilingual("Can you say that again?", uk: "Повторіть, будь ласка, ще раз."),
                    symbol: "repeat", kind: .social),
            .filler(.canYou, "phone", Bilingual("Phone", uk: "Телефон"),
                    says: Bilingual("Can you pass me my phone?", uk: "Подайте мені, будь ласка, мій телефон."),
                    symbol: "phone.fill", kind: .thing),
            .filler(.canYou, "turnOver", Bilingual("Turn over", uk: "Повернутися"),
                    says: Bilingual("Can you help me turn over?", uk: "Допоможіть мені, будь ласка, повернутися на бік."),
                    symbol: "arrow.counterclockwise", kind: .action),
            .filler(.canYou, "pillow", Bilingual("Pillow", uk: "Подушка"),
                    says: Bilingual("Can you fix my pillow?", uk: "Поправте мені, будь ласка, подушку."),
                    symbol: "bed.double.fill", kind: .thing),
        ],
        more: []
    )

    // MARK: - Where is…

    static let whereIs = SentenceFrame(
        id: .whereIs,
        starter: Bilingual("Where is…", uk: "Де…"),
        stem: Bilingual("Where is", uk: "Де"),
        symbol: "location.fill",
        kind: .question,
        fillers: [
            .filler(.whereIs, "phone", Bilingual("Phone", uk: "Телефон"),
                    says: Bilingual("Where is my phone?", uk: "Де мій телефон?"),
                    symbol: "phone.fill", kind: .thing),
            .filler(.whereIs, "glasses", Bilingual("Glasses", uk: "Окуляри"),
                    says: Bilingual("Where are my glasses?", uk: "Де мої окуляри?"),
                    symbol: "eyeglasses", kind: .thing),
            .filler(.whereIs, "family", Bilingual("Family", uk: "Родина"),
                    says: Bilingual("Where is my family?", uk: "Де моя родина?"),
                    symbol: "person.3.fill", kind: .people),
            .filler(.whereIs, "toilet", Bilingual("Toilet", uk: "Туалет"),
                    says: Bilingual("Where is the toilet?", uk: "Де туалет?"),
                    symbol: "toilet.fill", kind: .thing),
            .filler(.whereIs, "doctor", Bilingual("Doctor", uk: "Лікар"),
                    says: Bilingual("Where is the doctor?", uk: "Де лікар?"),
                    symbol: "stethoscope", kind: .people),
            .filler(.whereIs, "remote", Bilingual("TV remote", uk: "Пульт"),
                    says: Bilingual("Where is the TV remote?", uk: "Де пульт від телевізора?"),
                    symbol: "tv.fill", kind: .thing),
            .filler(.whereIs, "keys", Bilingual("Keys", uk: "Ключі"),
                    says: Bilingual("Where are my keys?", uk: "Де мої ключі?"),
                    symbol: "key.fill", kind: .thing),
            .filler(.whereIs, "documents", Bilingual("Documents", uk: "Документи"),
                    says: Bilingual("Where are my documents?", uk: "Де мої документи?"),
                    symbol: "envelope.fill", kind: .thing),
        ],
        more: [
            .filler(.whereIs, "wife", Bilingual("Wife", uk: "Дружина"),
                    says: Bilingual("Where is my wife?", uk: "Де моя дружина?"),
                    symbol: "heart.fill", kind: .people),
            .filler(.whereIs, "husband", Bilingual("Husband", uk: "Чоловік"),
                    says: Bilingual("Where is my husband?", uk: "Де мій чоловік?"),
                    symbol: "heart.fill", kind: .people),
            .filler(.whereIs, "nurse", Bilingual("Nurse", uk: "Медсестра"),
                    says: Bilingual("Where is the nurse?", uk: "Де медсестра?"),
                    symbol: "cross.case.fill", kind: .people),
        ]
    )
}
