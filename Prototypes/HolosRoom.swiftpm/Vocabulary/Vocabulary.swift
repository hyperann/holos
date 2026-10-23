import Foundation

/// Every phrase in both rooms, and the ways to find one.
///
/// The phrases themselves live with their rooms (`Vocabulary+Ward`,
/// `Vocabulary+Home`), each attached to the object it belongs to. That is
/// the whole idea of a scene board: "Medicine, please" is not filed under
/// a category called Needs, it sits on the bedside table where the pills are.
enum Vocabulary {
    /// How to reach a phrase: which room, and the ids pressed on the way —
    /// the hotspot, the person in the photo if there is one, then the phrase.
    struct Route: Sendable {
        let place: RoomPlace
        let ids: [String]
    }

    // MARK: - The judged goals

    /// "I'm in pain. Medicine, please." — the bed, then the bedside table.
    static let scanGoal = ["ward.bed.pain", "ward.table.medicine"]
    /// "Please call my wife." — found through her face in the family photo.
    static let familiarGoal = ["home.photo.wife.call"]

    /// What step 4 says in Ukrainian if step 2 was skipped with nothing said.
    static var defaultFirstMessage: [Phrase] {
        scanGoal.compactMap { phrase($0) }
    }

    // MARK: - Lookups

    static func hotspot(_ id: String) -> Hotspot? {
        hotspotsByID[id]
    }

    /// A phrase that is spoken when chosen (not a person in the photo).
    static func phrase(_ id: String) -> Phrase? {
        spokenByID[id]
    }

    /// Any cell's words — spoken phrases and photo people alike — for
    /// prompts and hints.
    static func cellPhrase(_ id: String) -> Phrase? {
        spokenByID[id] ?? topicsByID[id]?.phrase
    }

    /// A person in the family photo, who opens their own short list.
    static func topic(_ id: String) -> RoomChoice? {
        topicsByID[id]
    }

    static func route(to id: String) -> Route? {
        routesByID[id]
    }

    // MARK: - Tables, built once

    private static let hotspotsByID: [String: Hotspot] = {
        var table: [String: Hotspot] = [:]
        for spot in ward + home {
            table[spot.id] = spot
        }
        return table
    }()

    private static let spokenByID: [String: Phrase] = {
        var table: [String: Phrase] = [:]
        for spot in ward + home {
            for choice in spot.choices {
                if choice.opensMore {
                    for leaf in choice.more {
                        table[leaf.id] = leaf
                    }
                } else {
                    table[choice.id] = choice.phrase
                }
            }
        }
        return table
    }()

    private static let topicsByID: [String: RoomChoice] = {
        var table: [String: RoomChoice] = [:]
        for spot in ward + home {
            for choice in spot.choices where choice.opensMore {
                table[choice.id] = choice
            }
        }
        return table
    }()

    private static let routesByID: [String: Route] = {
        var table: [String: Route] = [:]
        for place in RoomPlace.allCases {
            for spot in place.hotspots {
                for choice in spot.choices {
                    if choice.opensMore {
                        for leaf in choice.more {
                            table[leaf.id] = Route(place: place, ids: [spot.id, choice.id, leaf.id])
                        }
                    } else {
                        table[choice.id] = Route(place: place, ids: [spot.id, choice.id])
                    }
                }
            }
        }
        return table
    }()
}
