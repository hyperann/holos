import Foundation

/// The four points of the compass, in the order the scan visits them.
///
/// Four is the whole idea. Four choices are few enough to hold in mind on a
/// bad day, big enough to see from a bed, and — because they sit in four
/// different directions — few enough for a head to *point* at.
enum Direction: String, CaseIterable, Identifiable, Sendable {
    case north
    case east
    case south
    case west

    var id: String { rawValue }

    /// Degrees clockwise from straight up: where the needle points.
    var degrees: Double {
        switch self {
        case .north: 0
        case .east: 90
        case .south: 180
        case .west: 270
        }
    }

    /// The petal's id in the scan.
    var stopID: String { "compass.\(rawValue)" }

    init?(stopID: String) {
        guard let match = Direction.allCases.first(where: { $0.stopID == stopID }) else { return nil }
        self = match
    }

    /// Drawn in a corner of each petal, so "up" means the same thing to the
    /// eye and to a head that is learning to point.
    var arrowSymbol: String {
        switch self {
        case .north: "arrow.up"
        case .east: "arrow.right"
        case .south: "arrow.down"
        case .west: "arrow.left"
        }
    }
}

/// What a petal does when it is chosen.
enum CompassAction: Hashable, Sendable {
    /// Opens the next four choices.
    case open(String)
    /// Speaks at once and is not kept: "Yes." and "No." are answers, not
    /// parts of a longer message.
    case answer(Bilingual)
    /// Speaks at once and joins the message, so the whole message can be
    /// said again together for the next person who walks in.
    case sentence(Bilingual)
}

/// One of the four petals on a level.
struct CompassChoice: Identifiable, Hashable, Sendable {
    let id: String
    /// One to three words on the petal.
    let label: Bilingual
    let symbol: String
    let kind: WordKind
    let action: CompassAction

    init(_ id: String, _ label: Bilingual, symbol: String, kind: WordKind, _ action: CompassAction) {
        self.id = id
        self.label = label
        self.symbol = symbol
        self.kind = kind
        self.action = action
    }

    var opensLevel: Bool {
        if case .open = action { return true }
        return false
    }

    /// The words this choice says aloud, if it says anything.
    var words: Bilingual? {
        switch action {
        case .open:
            return nil
        case .answer(let words), .sentence(let words):
            return words
        }
    }
}

/// One screen of the compass: four choices around the centre.
struct CompassLevel: Identifiable, Sendable {
    let id: String
    /// Where the path is heading, shown in yellow in the hub: "My head
    /// hurts…", or a heading such as «Де болить:» where a half sentence
    /// would not agree with every choice below it.
    let draft: Bilingual
    /// The short name in the trail at the top of the hub.
    let crumb: Bilingual
    let north: CompassChoice
    let east: CompassChoice
    let south: CompassChoice
    let west: CompassChoice

    func choice(_ direction: Direction) -> CompassChoice {
        switch direction {
        case .north: north
        case .east: east
        case .south: south
        case .west: west
        }
    }
}

/// One step on the way to a choice: on this level, take this direction.
struct CompassStep: Hashable, Sendable {
    let levelID: String
    let direction: Direction
}

/// The whole shallow tree of choices.
///
/// It is data, not code, so a speech therapist's version of the tree — or
/// a family's own — is a matter of editing a list, never the board.
struct CompassTree: Sendable {
    let home: CompassLevel
    private let levels: [String: CompassLevel]

    init(home: CompassLevel, levels: [CompassLevel]) {
        self.home = home
        var map: [String: CompassLevel] = [home.id: home]
        for level in levels {
            map[level.id] = level
        }
        self.levels = map
    }

    /// The level with this id. An unknown id lands on home rather than on
    /// an empty screen: a person must never be stranded by a typo in data.
    func level(_ id: String) -> CompassLevel {
        levels[id] ?? home
    }

    /// The steps from home to the choice with `choiceID`, or an empty list
    /// if no path reaches it. The guided step uses this to mark the next
    /// petal, wherever the person has wandered.
    func route(to choiceID: String) -> [CompassStep] {
        var visited: Set<String> = []
        return search(from: home, to: choiceID, visited: &visited) ?? []
    }

    /// The choice with this id, wherever it sits in the tree.
    func choice(id: String) -> CompassChoice? {
        guard let last = route(to: id).last else { return nil }
        return level(last.levelID).choice(last.direction)
    }

    private func search(from level: CompassLevel, to target: String, visited: inout Set<String>) -> [CompassStep]? {
        guard visited.insert(level.id).inserted else { return nil }
        for direction in Direction.allCases {
            let choice = level.choice(direction)
            let step = CompassStep(levelID: level.id, direction: direction)
            if choice.id == target {
                return [step]
            }
            if case .open(let nextID) = choice.action,
               let next = levels[nextID],
               let rest = search(from: next, to: target, visited: &visited) {
                return [step] + rest
            }
        }
        return nil
    }
}
