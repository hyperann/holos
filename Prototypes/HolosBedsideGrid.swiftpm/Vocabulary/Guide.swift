/// A guided goal: the cells to say, in order, and where each one lives.
///
/// The guide never insists on a path. It reads the message the person has
/// built so far, finds the first goal cell still missing (extra or wrong
/// cells in between are simply ignored — a mis-scan is never punished) and
/// points at whatever gets them there next: the topic, the cell, or Speak.
struct Guide: Equatable, Sendable {
    struct Stop: Equatable, Sendable {
        let phrase: Phrase
        let topic: Topic
    }

    let stops: [Stop]

    var phrases: [Phrase] { stops.map(\.phrase) }

    /// What the finished message will say, e.g. "Please call my wife."
    var sentence: Bilingual { Bilingual.joined(phrases.map(\.speech)) }

    /// The first goal cell `message` is still missing, or nil once every
    /// stop is in it, in order.
    func nextStop(after message: [Phrase]) -> Stop? {
        var matched = 0
        for phrase in message where matched < stops.count && phrase.id == stops[matched].phrase.id {
            matched += 1
        }
        return stops.indices.contains(matched) ? stops[matched] : nil
    }

    func target(message: [Phrase], topic: Topic) -> GuideTarget {
        guard let stop = nextStop(after: message) else { return .speak }
        return stop.topic == topic ? .cell(stop.phrase, on: stop.topic) : .topic(stop.topic)
    }
}

/// Where the guide's "This one" tag sits on the whole board.
enum GuideTarget: Equatable, Sendable {
    /// A cell, with the topic it is on.
    case cell(Phrase, on: Topic)
    case topic(Topic)
    case speak
}
