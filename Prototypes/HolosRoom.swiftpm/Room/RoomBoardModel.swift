import Foundation
import Observation

/// The room as a board: which room is showing, what is open, what was
/// just said — and the scanner that walks it.
///
/// It knows nothing about the story; `Experience` decides when the board is
/// live and what a choice means for the step. Keeping the two apart is what
/// lets the same room serve the judged flow and free talking afterwards.
@MainActor
@Observable
final class RoomBoardModel {
    var place: RoomPlace = .ward
    /// What is open in touch mode: a hotspot, then perhaps a person in the
    /// photo. In scanning mode the scanner's own path plays this part.
    var touchPath: [String] = []
    private(set) var spoken: SpokenLine?

    let scanner = Scanner()

    @ObservationIgnored private var spokenSerial = 0
    @ObservationIgnored private var spokenTimer: Task<Void, Never>?

    /// Long enough to read a short sentence twice; short enough that the
    /// next choice is never answered by the last one's bubble.
    private static let bubbleSeconds = 4.0

    func reset(to place: RoomPlace) {
        self.place = place
        touchPath = []
        clearSpoken()
    }

    // MARK: - The scan

    /// The top level of the scan. Hotspots first, in reading order, then the
    /// room switch, the language and the message — so the room itself is
    /// always the quickest thing to reach.
    func tree(includeHelp: Bool) -> [ScanNode] {
        var nodes: [ScanNode] = []
        if includeHelp {
            // First, so someone who has been stuck needs one press, not a loop.
            nodes.append(.item(RoomIDs.helpChip))
        }
        nodes += place.hotspots.map(\.scanNode)
        nodes.append(.item(RoomIDs.sceneChip))
        nodes.append(.item(RoomIDs.languageChip))
        nodes.append(MessageBar.scanRow)
        return nodes
    }

    // MARK: - What is open

    func openPath(isScanning: Bool) -> [String] {
        guard isScanning else { return touchPath }
        // A stopped scan keeps its last path; nothing is open any more.
        return scanner.state == .stopped ? [] : scanner.path
    }

    /// The hotspot whose ring is showing, if any. (The scanner's path can
    /// also hold the message row, which is not a hotspot.)
    func openHotspot(isScanning: Bool) -> Hotspot? {
        guard let first = openPath(isScanning: isScanning).first,
              let spot = Vocabulary.hotspot(first),
              place.hotspots.contains(where: { $0.id == spot.id })
        else { return nil }
        return spot
    }

    /// The person opened inside the family photo, if any.
    func openTopic(isScanning: Bool) -> RoomChoice? {
        let path = openPath(isScanning: isScanning)
        guard path.count >= 2 else { return nil }
        return Vocabulary.topic(path[1])
    }

    /// The cells around the open hotspot, ending with its "go back" cell —
    /// the same cells, in the same order, that the scanner visits.
    func ringItems(isScanning: Bool) -> [RingItem] {
        guard let spot = openHotspot(isScanning: isScanning) else { return [] }
        if let topic = openTopic(isScanning: isScanning) {
            let sentences = topic.more.map { RingItem(id: $0.id, choice: RoomChoice($0)) }
            return sentences + [RingItem(id: Scanner.backID(for: topic.id), choice: nil)]
        }
        let cells = spot.choices.map { RingItem(id: $0.id, choice: $0) }
        return cells + [RingItem(id: Scanner.backID(for: spot.id), choice: nil)]
    }

    // MARK: - What was said

    /// Shows the person's words as a speech bubble in the room for a few
    /// seconds — the visual third of every spoken choice.
    func showSpoken(_ words: Bilingual) {
        spokenSerial += 1
        spoken = SpokenLine(serial: spokenSerial, words: words)
        spokenTimer?.cancel()
        let seconds = Self.bubbleSeconds
        spokenTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.spoken = nil
        }
    }

    func clearSpoken() {
        spokenTimer?.cancel()
        spokenTimer = nil
        spoken = nil
    }
}
