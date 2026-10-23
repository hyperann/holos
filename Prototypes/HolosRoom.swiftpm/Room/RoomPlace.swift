import Foundation

/// The two rooms on the board.
///
/// The ward is where the judged story starts — the place a person first
/// wakes up without words. Home is the familiar room: the one whose objects
/// carry the most memory, and so the most words.
enum RoomPlace: String, CaseIterable, Identifiable, Sendable {
    case ward
    case home

    var id: String { rawValue }

    var other: RoomPlace {
        switch self {
        case .ward: .home
        case .home: .ward
        }
    }

    var name: Bilingual {
        switch self {
        case .ward: Copy.placeWard
        case .home: Copy.placeHome
        }
    }

    /// One sentence that tells a VoiceOver user what the picture shows.
    var sceneDescription: Bilingual {
        switch self {
        case .ward: Copy.wardDescription
        case .home: Copy.homeDescription
        }
    }

    /// Ordered the way the eye crosses the room, left to right by where each
    /// object begins: the scan should never jump somewhere a person is not
    /// looking.
    var hotspots: [Hotspot] {
        switch self {
        case .ward: Vocabulary.ward
        case .home: Vocabulary.home
        }
    }

    /// Where the person is in the picture, so their speech bubble comes
    /// from them: the patient in the bed, the person on the sofa.
    var speakerAt: ArtPoint {
        switch self {
        case .ward: ArtPoint(236, 380)
        case .home: ArtPoint(506, 296)
        }
    }

    /// The chip that leads from this room to the other one.
    var switchLabel: Bilingual {
        switch self {
        case .ward: Copy.goHome
        case .home: Copy.goWard
        }
    }

    var switchSymbol: String {
        switch self {
        case .ward: "house.fill"
        case .home: "cross.case.fill"
        }
    }
}
