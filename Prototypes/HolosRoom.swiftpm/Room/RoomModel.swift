import CoreGraphics
import Foundation

/// The fixed space every room is drawn in.
///
/// Each scene is drawn once, at 1000 × 700, and scaled to whatever screen
/// it lands on. Hotspots are described in that same space, so the picture
/// and the places you can press can never drift apart on a different iPad.
enum RoomSpace {
    static let width: CGFloat = 1000
    static let height: CGFloat = 700
    static let aspect: CGFloat = width / height
}

/// A rectangle in room space. Plain doubles, so the vocabulary tables can
/// be shared freely between threads (Swift 6 checks that they can).
struct ArtRect: Hashable, Sendable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(_ x: Double, _ y: Double, _ width: Double, _ height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    var center: ArtPoint { ArtPoint(x + width / 2, y + height / 2) }

    /// This rectangle in on-screen points, for a room drawn at `scale`.
    func scaled(_ scale: CGFloat) -> CGRect {
        CGRect(x: CGFloat(x) * scale, y: CGFloat(y) * scale, width: CGFloat(width) * scale, height: CGFloat(height) * scale)
    }
}

/// A point in room space.
struct ArtPoint: Hashable, Sendable {
    let x: Double
    let y: Double

    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    func scaled(_ scale: CGFloat) -> CGPoint {
        CGPoint(x: CGFloat(x) * scale, y: CGFloat(y) * scale)
    }
}

/// One thing you can say about a place in the room — or, for the family
/// photo, a person who opens their own short list.
///
/// The photo is where the concept earns its keep: Yuriy cannot recall the
/// word "wife", but he can recognise her face. Choosing the face offers the
/// sentences that go with it, so the word comes to him instead of the other
/// way round.
struct RoomChoice: Identifiable, Hashable, Sendable {
    /// What the cell shows; spoken when the choice is a leaf.
    let phrase: Phrase
    /// When not empty, choosing this opens these instead of speaking.
    let more: [Phrase]

    init(_ phrase: Phrase, more: [Phrase] = []) {
        self.phrase = phrase
        self.more = more
    }

    var id: String { phrase.id }
    var opensMore: Bool { !more.isEmpty }
}

/// A place in the room the light can rest on: the bed, the window, the
/// family photo.
struct Hotspot: Identifiable, Hashable, Sendable {
    let id: String
    /// What the object is — the pill on the picture and its VoiceOver label.
    let name: Bilingual
    /// The area that lights up, in room space.
    let frame: ArtRect
    /// Where the name pill sits, in room space. Always inside `frame`, so the
    /// pill is lit together with its object.
    let labelAt: ArtPoint
    let choices: [RoomChoice]

    init(id: String, name: Bilingual, frame: ArtRect, labelAt: ArtPoint, choices: [RoomChoice]) {
        self.id = id
        self.name = name
        self.frame = frame
        self.labelAt = labelAt
        self.choices = choices
    }

    /// The hotspot as one group in the scan: entering it blooms its ring.
    var scanNode: ScanNode {
        let children = choices.map { choice -> ScanNode in
            if choice.opensMore {
                return ScanNode.group(choice.id, choice.more.map { ScanNode.item($0.id) })
            }
            return ScanNode.item(choice.id)
        }
        return ScanNode.group(id, children)
    }
}

/// Ids for everything in the scan that is not a hotspot or a phrase.
enum RoomIDs {
    /// "Go home" / "To the ward".
    static let sceneChip = "chip.scene"
    /// The language switch, inside the scan so a switch user can reach it.
    static let languageChip = "chip.language"
    /// "Show me" — offered only after a long wait in a guided step.
    static let helpChip = "chip.help"

    static let sayUkrainian = "card.sayUkrainian"
    static let cardContinue = "card.continue"
    static let keepTalking = "card.keepTalking"
    static let startAgain = "card.startAgain"
}

/// One cell of the ring that blooms around an opened hotspot.
///
/// The id is stored, not computed, because a back cell's id comes from
/// `Scanner.backID(for:)`, which lives on the main actor; the ring is built
/// there (in `RoomBoardModel`) and this value just carries the result.
struct RingItem: Identifiable, Hashable, Sendable {
    let id: String
    /// The choice this cell shows, or nil for the ring's "go back" cell.
    let choice: RoomChoice?
}

/// The last thing the person said, shown as a speech bubble in the room.
struct SpokenLine: Equatable, Sendable {
    /// Counts up, so saying the same words twice still redraws the bubble.
    let serial: Int
    let words: Bilingual
}
