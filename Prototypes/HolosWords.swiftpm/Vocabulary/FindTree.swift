import Foundation

/// One screen of Find a word: a question, and the answers that narrow it.
///
/// This borrows the questions of semantic feature analysis, the anomia
/// therapy in which a person describes a word's features, and uses them to
/// narrow the board until the word is one of a few pictures to *recognise*.
/// Recognising is far easier than recalling, and that gap is the whole
/// idea. So every answer has to be a true description of the words behind
/// it: a person who describes the word honestly must never hit a dead end.
struct FindCategory: Identifiable, Sendable {
    let id: String
    /// How the category reads on the screen that offers it: "A person".
    let label: Bilingual
    let symbol: String
    let kind: WordKind
    /// The question asked on the screen this category opens.
    let question: Bilingual
    /// Two to five answers: more would turn recognising back into searching.
    let options: [FindOption]
}

/// An answer on a Find a word screen: either a narrower question, or a word.
enum FindOption: Identifiable, Sendable {
    case category(FindCategory)
    /// A word, named by its concept. `home` is the starter it belongs with
    /// when the open starter cannot take it (see `Vocabulary.resolve`).
    case word(concept: String, home: FrameID)

    static func key(category id: String) -> String { "cat." + id }
    static func key(word concept: String) -> String { "word." + concept }

    var id: String {
        switch self {
        case .category(let category): Self.key(category: category.id)
        case .word(let concept, _): Self.key(word: concept)
        }
    }
}

/// The whole Find a word tree. Every word here maps onto a sentence in
/// `Vocabulary`; most of them are words the board itself has no room for.
enum FindTree {
    static let root = FindCategory(
        id: "root",
        label: Copy.findWord,
        symbol: "magnifyingglass",
        kind: .control,
        question: Bilingual("What is it?", uk: "Що це?"),
        options: [.category(person), .category(thing), .category(place), .category(action), .category(feeling)]
    )

    // MARK: - A person

    static let person = FindCategory(
        id: "person",
        label: Bilingual("A person", uk: "Людина"),
        symbol: "person.fill",
        kind: .people,
        question: Bilingual("Who is it?", uk: "Хто це?"),
        options: [.category(family), .category(staff), .category(friends), .category(service)]
    )

    static let family = FindCategory(
        id: "family",
        label: Bilingual("Family", uk: "Родина"),
        symbol: "person.3.fill",
        kind: .people,
        // Generations, not ages: a younger brother is still "my generation",
        // and a person can answer this truthfully for every word below.
        question: Bilingual("Which generation?", uk: "Яке покоління?"),
        options: [.category(older), .category(sameAge), .category(younger)]
    )

    static let older = FindCategory(
        id: "older",
        label: Bilingual("Older generation", uk: "Старше покоління"),
        symbol: "figure.stand",
        kind: .people,
        question: whoExactly,
        options: words(.call, ["mum", "dad", "grandma", "grandpa"])
    )

    static let sameAge = FindCategory(
        id: "sameAge",
        label: Bilingual("My generation", uk: "Моє покоління"),
        symbol: "person.2.fill",
        kind: .people,
        question: whoExactly,
        options: words(.call, ["wife", "husband", "brother", "sister"])
    )

    static let younger = FindCategory(
        id: "younger",
        label: Bilingual("Younger generation", uk: "Молодше покоління"),
        symbol: "figure.and.child.holdinghands",
        kind: .people,
        question: whoExactly,
        options: words(.call, ["son", "daughter", "grandson", "granddaughter"])
    )

    static let staff = FindCategory(
        id: "staff",
        label: Bilingual("Doctors and staff", uk: "Медики"),
        symbol: "stethoscope",
        kind: .people,
        question: whoExactly,
        options: words(.need, ["doctor", "nurse", "speechTherapist", "physio"])
    )

    static let friends = FindCategory(
        id: "friends",
        label: Bilingual("Friends and neighbours", uk: "Друзі й сусіди"),
        symbol: "hand.wave.fill",
        kind: .people,
        question: whoExactly,
        options: words(.call, ["friend", "neighbour"])
    )

    /// A commander is not a friend, so the people someone served with have
    /// a door of their own rather than hiding under "Friends".
    static let service = FindCategory(
        id: "service",
        label: Bilingual("Military service", uk: "Служба"),
        symbol: "star.fill",
        kind: .people,
        question: whoExactly,
        options: words(.call, ["comrade", "commander"])
    )

    // MARK: - A thing

    static let thing = FindCategory(
        id: "thing",
        label: Bilingual("A thing", uk: "Річ"),
        symbol: "bag.fill",
        kind: .thing,
        question: Bilingual("What kind of thing?", uk: "Яка це річ?"),
        options: [.category(mine), .category(foodAndDrink), .category(room)]
    )

    static let mine = FindCategory(
        id: "mine",
        label: Bilingual("My things", uk: "Мої речі"),
        symbol: "key.fill",
        kind: .thing,
        question: whichOne,
        options: words(.whereIs, ["phone", "glasses", "keys", "documents"])
    )

    static let foodAndDrink = FindCategory(
        id: "foodAndDrink",
        label: Bilingual("Food and drink", uk: "Їжа й напої"),
        symbol: "fork.knife",
        kind: .thing,
        question: whichOne,
        options: [
            .word(concept: "water", home: .need),
            .word(concept: "tea", home: .want),
            .word(concept: "food", home: .want),
        ]
    )

    static let room = FindCategory(
        id: "room",
        label: Bilingual("In the room", uk: "У кімнаті"),
        symbol: "lamp.table.fill",
        kind: .thing,
        question: whichOne,
        options: [
            .word(concept: "blanket", home: .need),
            .word(concept: "pillow", home: .canYou),
            .word(concept: "remote", home: .whereIs),
            .word(concept: "light", home: .canYou),
        ]
    )

    // MARK: - A place

    static let place = FindCategory(
        id: "place",
        label: Bilingual("A place", uk: "Місце"),
        symbol: "location.fill",
        kind: .thing,
        question: Bilingual("Which place?", uk: "Яке місце?"),
        options: [
            .word(concept: "home", home: .want),
            .word(concept: "toilet", home: .need),
            .word(concept: "garden", home: .want),
            .word(concept: "shower", home: .want),
        ]
    )

    // MARK: - Doing something

    static let action = FindCategory(
        id: "action",
        label: Bilingual("Doing something", uk: "Дія"),
        symbol: "figure.walk",
        kind: .action,
        question: Bilingual("Moving, or something you do every day?", uk: "Рух чи щоденні справи?"),
        options: [.category(moving), .category(daily)]
    )

    static let moving = FindCategory(
        id: "moving",
        label: Bilingual("Moving", uk: "Рух"),
        symbol: "shoeprints.fill",
        kind: .action,
        question: whichOne,
        options: [
            .word(concept: "sitUp", home: .want),
            .word(concept: "lieDown", home: .want),
            .word(concept: "walk", home: .want),
            .word(concept: "turnOver", home: .canYou),
        ]
    )

    static let daily = FindCategory(
        id: "daily",
        label: Bilingual("Every day", uk: "Щоденні справи"),
        symbol: "sunrise.fill",
        kind: .action,
        question: whichOne,
        options: words(.want, ["sleep", "wash", "drink", "tv"])
    )

    // MARK: - A feeling

    static let feeling = FindCategory(
        id: "feeling",
        label: Bilingual("A feeling", uk: "Відчуття"),
        symbol: "heart.fill",
        kind: .describing,
        question: Bilingual("In your body, or in your mood?", uk: "У тілі чи на душі?"),
        options: [.category(body), .category(mood)]
    )

    static let body = FindCategory(
        id: "body",
        label: Bilingual("In my body", uk: "У тілі"),
        symbol: "figure.stand",
        kind: .describing,
        question: whichOne,
        options: words(.feel, ["pain", "sick", "dizzy", "cold"])
    )

    static let mood = FindCategory(
        id: "mood",
        label: Bilingual("My mood", uk: "На душі"),
        symbol: "face.smiling",
        kind: .describing,
        question: whichOne,
        options: words(.feel, ["sad", "scared", "bored", "better"])
    )

    // MARK: - Helpers

    private static let whoExactly = Bilingual("Who exactly?", uk: "Хто саме?")
    private static let whichOne = Bilingual("Which one?", uk: "Що саме?")

    private static func words(_ home: FrameID, _ concepts: [String]) -> [FindOption] {
        concepts.map { FindOption.word(concept: $0, home: home) }
    }
}
