import Foundation
import Observation

/// Something the scanner can land on.
///
/// One tree describes every scanning style the prototypes use:
/// - Row-column: the top level is rows (`.group`), each holding cells.
/// - Linear: the top level is just `.item`s.
/// - Zones or quadrants: groups nested as deep as the board needs.
indirect enum ScanNode: Hashable, Sendable {
    /// Something to choose. Its id is reported when it is selected.
    case item(String)
    /// A set of nodes entered with one press: a row, a zone of a scene.
    case group(String, [ScanNode])

    var id: String {
        switch self {
        case .item(let id): id
        case .group(let id, _): id
        }
    }
}

/// What just happened in the scan. `ScanBinding` turns these into the
/// standard feel; a screen can also listen for its own reasons.
enum ScanEvent: Equatable, Sendable {
    /// The highlight moved on by itself.
    case moved(to: String)
    /// A press opened a group; the first thing inside is now lit.
    case entered(group: String)
    /// A press chose an item.
    case selected(item: String)
    /// A press on a group's "go back" cell, or two silent loops inside a
    /// group, returned to the level above.
    case backedOut(of: String)
    /// Nobody pressed for several loops, so the scan stopped and waits.
    case paused
    /// A press woke a paused scan.
    case resumed
}

/// The single-switch scanning engine.
///
/// It owns no views and knows nothing about cells — only ids. A screen
/// gives it a tree with `load(_:)`, draws a highlight wherever
/// `highlightedID` points, and forwards presses to `press()`. Writing the
/// scanning logic once is what lets every board, every prototype, and
/// every input share the same behaviour.
///
/// The behaviour follows ordinary clinical practice for switch scanning:
/// - The first thing in a newly entered level stays lit a little longer,
///   so a person who has just pressed has time to see where they are.
/// - Every group ends with a "go back" cell, so a wrong row costs one
///   press, not a full loop.
/// - Two silent loops inside a group step back out by themselves; three
///   silent loops at the top pause the scan until the next press, so the
///   board is not flashing at someone who has stopped to rest.
@MainActor
@Observable
final class Scanner {
    enum State: Equatable, Sendable {
        case stopped
        case scanning
        case paused
    }

    private(set) var state: State = .stopped
    /// The id now lit: a group, an item, or a group's back cell
    /// (see `backID(for:)`).
    private(set) var highlightedID: String?
    /// The groups entered, outermost first. A row-column board uses it to
    /// dim the rows that are not in play.
    private(set) var path: [String] = []

    /// Called on every scan event. Set it with `ScanBinding.bind` for the
    /// standard feel, or directly.
    @ObservationIgnored var onEvent: ((ScanEvent) -> Void)?
    /// Called when a scan starts from the top — `load(_:start: true)` or
    /// `start()` — so the first lit item can be announced like every other.
    /// (A hook rather than a `ScanEvent` case, so switches over `ScanEvent`
    /// elsewhere stay exhaustive.)
    @ObservationIgnored var onStart: (() -> Void)?
    /// Asked after every step's wait: while it returns true, the highlight
    /// stays where it is. `ScanBinding` uses it to let a spoken prompt
    /// finish before the scan moves on. Capped at three seconds per step,
    /// so a lost "finished" callback can never freeze the scan.
    @ObservationIgnored var holdsStep: () -> Bool = { false }
    /// While this returns true the scan does not move at all — no cap.
    /// `ScanBinding` ties it to `SwitchHub.isSuspended`, so the board
    /// behind an open Settings sheet stays exactly where it was.
    @ObservationIgnored var isSuspended: () -> Bool = { false }
    /// Seconds per step, read fresh on every step so a speed change in
    /// Settings applies immediately.
    @ObservationIgnored var stepSeconds: () -> Double = { 1.4 }
    /// After a selection, start again from the top (the usual practice) or
    /// stay inside the same group (useful for a row of letters or numbers).
    @ObservationIgnored var returnsToTopAfterSelection = true
    /// Adds a "go back" cell at the end of every group.
    @ObservationIgnored var addsBackCells = true
    @ObservationIgnored var loopsBeforeLeavingGroup = 2
    @ObservationIgnored var loopsBeforePause = 3
    /// How much longer the first item of a newly entered level stays lit.
    @ObservationIgnored var firstStepFactor = 1.5

    @ObservationIgnored private var root: [ScanNode] = []
    @ObservationIgnored private var stack: [(id: String, children: [ScanNode])] = []
    @ObservationIgnored private var cursor = 0
    @ObservationIgnored private var loopsCompleted = 0
    @ObservationIgnored private var ticker: Task<Void, Never>?

    init() {}

    // MARK: - Ids

    static let backSuffix = "#back"

    /// The id of the "go back" cell at the end of `groupID`.
    static func backID(for groupID: String) -> String { groupID + backSuffix }

    static func isBackID(_ id: String) -> Bool { id.hasSuffix(backSuffix) }

    /// True when `id` is the one thing lit right now.
    func isHighlighted(_ id: String) -> Bool {
        highlightedID == id
    }

    /// True when `id` is a group the scanner has entered — so a row can
    /// stay outlined while its cells are being scanned.
    func isEntered(_ id: String) -> Bool {
        path.contains(id)
    }

    // MARK: - Control

    /// Replaces the tree and starts again from its first node.
    ///
    /// Empty groups are dropped: a press on one would do nothing at all,
    /// and a switch user cannot tell a dead row from a missed press.
    func load(_ nodes: [ScanNode], start: Bool = true) {
        root = Self.pruned(nodes)
        stack.removeAll()
        path.removeAll()
        cursor = 0
        loopsCompleted = 0
        if start {
            state = .scanning
            highlightedID = currentEntries().first.map(Self.id(of:))
            restartTicker(longFirstStep: true)
            onStart?()
        } else {
            state = .stopped
            highlightedID = nil
            ticker?.cancel()
            ticker = nil
        }
    }

    func start() {
        guard state != .scanning else { return }
        stack.removeAll()
        path.removeAll()
        cursor = 0
        loopsCompleted = 0
        state = .scanning
        highlightedID = currentEntries().first.map(Self.id(of:))
        restartTicker(longFirstStep: true)
        onStart?()
    }

    func stop() {
        state = .stopped
        highlightedID = nil
        // A stopped scan is inside nothing, so no row stays outlined or
        // dimmed after the board switches to touch.
        stack.removeAll()
        path.removeAll()
        cursor = 0
        loopsCompleted = 0
        ticker?.cancel()
        ticker = nil
    }

    /// The switch. Picks whatever is lit.
    func press() {
        switch state {
        case .stopped:
            return
        case .paused:
            start()
            onEvent?(.resumed)
            return
        case .scanning:
            break
        }

        let entries = currentEntries()
        guard entries.indices.contains(cursor) else { return }
        switch entries[cursor] {
        case .back(let groupID):
            leaveGroup()
            restartTicker(longFirstStep: true)
            onEvent?(.backedOut(of: groupID))

        case .node(.group(let id, let children)):
            guard !children.isEmpty else { return }
            stack.append((id: id, children: children))
            path.append(id)
            cursor = 0
            loopsCompleted = 0
            highlightedID = currentEntries().first.map(Self.id(of:))
            restartTicker(longFirstStep: true)
            onEvent?(.entered(group: id))

        case .node(.item(let id)):
            if returnsToTopAfterSelection {
                stack.removeAll()
                path.removeAll()
            }
            cursor = 0
            loopsCompleted = 0
            highlightedID = currentEntries().first.map(Self.id(of:))
            restartTicker(longFirstStep: true)
            // Last, so a handler that loads a new board or stops the scan
            // has the final word.
            onEvent?(.selected(item: id))
        }
    }

    // MARK: - Stepping

    private enum Entry {
        case node(ScanNode)
        case back(String)
    }

    private static func id(of entry: Entry) -> String {
        switch entry {
        case .node(let node): node.id
        case .back(let groupID): backID(for: groupID)
        }
    }

    private static func pruned(_ nodes: [ScanNode]) -> [ScanNode] {
        nodes.compactMap { node -> ScanNode? in
            switch node {
            case .item:
                return node
            case .group(let id, let children):
                let kept = pruned(children)
                return kept.isEmpty ? nil : .group(id, kept)
            }
        }
    }

    private func currentEntries() -> [Entry] {
        guard let level = stack.last else { return root.map(Entry.node) }
        var entries = level.children.map(Entry.node)
        if addsBackCells {
            entries.append(.back(level.id))
        }
        return entries
    }

    /// Pops one level and puts the highlight back on the group just left,
    /// so the person resumes where they were rather than at the top.
    private func leaveGroup() {
        guard let left = stack.popLast() else { return }
        path.removeLast()
        loopsCompleted = 0
        let entries = currentEntries()
        cursor = entries.firstIndex { Self.id(of: $0) == left.id } ?? 0
        highlightedID = entries.indices.contains(cursor) ? Self.id(of: entries[cursor]) : nil
    }

    private func advance() {
        guard state == .scanning else { return }
        let entries = currentEntries()
        guard !entries.isEmpty else { return }
        cursor += 1
        if cursor >= entries.count {
            cursor = 0
            loopsCompleted += 1
            if let level = stack.last, loopsCompleted >= loopsBeforeLeavingGroup {
                leaveGroup()
                restartTicker(longFirstStep: true)
                onEvent?(.backedOut(of: level.id))
                return
            }
            if stack.isEmpty, loopsCompleted >= loopsBeforePause {
                state = .paused
                highlightedID = nil
                ticker?.cancel()
                ticker = nil
                onEvent?(.paused)
                return
            }
        }
        let id = Self.id(of: entries[cursor])
        highlightedID = id
        onEvent?(.moved(to: id))
    }

    private func restartTicker(longFirstStep: Bool) {
        ticker?.cancel()
        guard state == .scanning else {
            ticker = nil
            return
        }
        let first = stepSeconds() * (longFirstStep ? firstStepFactor : 1)
        ticker = Task { [weak self] in
            var wait = first
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(max(wait, 0.2)))
                var held = 0.0
                var wasSuspended = false
                while !Task.isCancelled,
                      self?.isSuspended() == true || (held < 3 && self?.holdsStep() == true) {
                    if self?.isSuspended() == true { wasSuspended = true }
                    try? await Task.sleep(for: .milliseconds(100))
                    held += 0.1
                }
                guard !Task.isCancelled, let self else { return }
                if wasSuspended {
                    // Back from Settings: give the lit item a full first-step
                    // dwell before moving on, rather than jumping at once.
                    wait = self.stepSeconds() * self.firstStepFactor
                    continue
                }
                self.advance()
                wait = self.stepSeconds()
            }
        }
    }
}
