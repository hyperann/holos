import Foundation
import Observation

/// Scan stops beyond the four petals.
enum CompassStop {
    /// The centre: speaks the whole message.
    static let hub = "compass.hub"
    /// Below home: one level up.
    static let back = "compass.back"
    /// Two or more levels below home: straight back to home, keeping the
    /// message. One level down it would only be a second Back.
    static let backToStart = "compass.backToStart"
    /// At home: the other language.
    static let language = "compass.language"
    /// At home, once there is a message: start a new one. Scanned, it is a
    /// group that opens on "No, keep it", with "Yes, clear all" lit one
    /// step later — so a double press keeps the message, the same rule as
    /// Core's message bar.
    static let clear = "compass.clear"
    static let clearCancel = "compass.clear.cancel"
    static let clearConfirm = "compass.clear.confirm"
}

/// What happened on the board, for a guided step to react to.
enum CompassEvent: Equatable, Sendable {
    /// A choice that speaks was chosen. `kept` is true for sentences that
    /// joined the message, false for quick answers such as "Yes".
    case said(choiceID: String, kept: Bool)
    /// The whole message was spoken from the centre.
    case spokeMessage
    /// One of the step's own extra stops was chosen.
    case extra(String)
}

/// How a choice arrived. Scanned choices already got their "select"
/// feedback from `Scanner.bind`; touched and pointed ones need their own.
enum ChoiceSource: Sendable {
    case scan
    case touch
    case pointing
}

/// One compass board: where the person is in the tree, the scan over it,
/// and what each stop does.
///
/// Every level is scanned as one flat ring of stops, always in the same
/// order — north, east, south, west, then the centre (Speak), then the
/// chips under it. That makes the scan a single clockwise sweep the person
/// can learn by feel: the fifth stop is always Speak; the sixth is Back
/// below home and the language at home (plus Clear once there is a
/// message).
///
/// What sits under the centre changes with the level, and that is the
/// design choice worth defending:
/// - Below home it is **Back**, because a wrong turn must cost one press.
///   Two or more levels down, **Back to start** follows it, so getting home
///   from deep in the tree never costs a full ring per level. It keeps the
///   message, so it asks for nothing more.
/// - At home there is nothing to go back to, so it is the **language**.
///   Language is a choice made before a sentence, never in the middle of
///   one, so home is exactly where it belongs.
/// - At home with a message waiting, **Clear** follows it: the only way to
///   start a fresh message, and absent while there is nothing to clear.
///   Scanned, it opens on "No, keep it", and only "Yes, clear all", lit one
///   step later, clears — so one stray or doubled press never loses a
///   message.
@MainActor
@Observable
final class CompassController {
    let tree: CompassTree
    let scanner: Scanner
    /// Level ids from home to here. Never empty.
    private(set) var trail: [String]
    /// A just-chosen petal, briefly, so a quick answer like "Yes" visibly
    /// lands even though the board does not change.
    private(set) var flashID: String?
    /// The step's own stops, scanned after the centre's.
    private(set) var extraStops: [String] = []
    private(set) var isRunning = false
    private(set) var isScanning = false

    @ObservationIgnored var onEvent: ((CompassEvent) -> Void)?
    /// Words for the step's own stops, for auditory prompts.
    @ObservationIgnored var extraLabel: (String) -> Bilingual? = { _ in nil }
    @ObservationIgnored private var services: HolosServices?
    @ObservationIgnored private var pointer: HeadPointer?
    @ObservationIgnored private var flashTask: Task<Void, Never>?
    @ObservationIgnored private var handlingScanSelection = false

    init(tree: CompassTree = Vocabulary.tree) {
        self.tree = tree
        scanner = Scanner()
        trail = [tree.home.id]
    }

    // MARK: - Where we are

    var level: CompassLevel { tree.level(trail.last ?? tree.home.id) }
    var isHome: Bool { trail.count <= 1 }
    /// True two or more levels down, where Back to start is offered.
    var offersBackToStart: Bool { trail.count > 2 }
    /// The crumbs after home: "I feel › Pain › Head".
    var crumbs: [Bilingual] { trail.dropFirst().map { tree.level($0).crumb } }
    var isPointing: Bool { pointer?.isPointing ?? false }

    /// The ring of stops for this level, in scan order.
    var stopIDs: [String] {
        var ids = Direction.allCases.map(\.stopID)
        ids.append(CompassStop.hub)
        if isHome {
            ids.append(CompassStop.language)
            if let message = services?.message, !message.isEmpty {
                ids.append(CompassStop.clear)
            }
        } else {
            ids.append(CompassStop.back)
            if offersBackToStart {
                ids.append(CompassStop.backToStart)
            }
        }
        return ids + extraStops
    }

    /// The stop that leads towards `choiceID` from here: the right petal
    /// while the person is on the way, Back once they have wandered off it.
    /// Nothing is ever a wrong answer — it only changes where the marker is.
    func guide(toward choiceID: String) -> String? {
        let route = tree.route(to: choiceID)
        guard !route.isEmpty else { return nil }
        if let step = route.first(where: { $0.levelID == level.id }) {
            return step.direction.stopID
        }
        return isHome ? nil : CompassStop.back
    }

    // MARK: - Running

    func attach(services: HolosServices, pointer: HeadPointer) {
        self.services = services
        self.pointer = pointer
        // Clear is the only group on this board, and its "No, keep it" is
        // already the way out: a back cell would only be a second No, and
        // a third chip that does not fit at phone width. Two quiet loops
        // still step out of the group by themselves.
        scanner.addsBackCells = false
        scanner.bind(to: services, label: { [weak self] id in
            self?.label(for: id)
        }, onSelect: { [weak self] id in
            self?.scanSelected(id)
        })
    }

    func start(scanning: Bool) {
        isRunning = true
        isScanning = scanning
        pointer?.onChoose = { [weak self] direction in
            self?.choose(direction, via: .pointing)
        }
        pointer?.onRestBack = { [weak self] in
            self?.restBack()
        }
        pointer?.restBackAllowed = { [weak self] in
            guard let self else { return false }
            return self.isRunning && !self.isHome
        }
        reloadScan()
    }

    func stop() {
        isRunning = false
        scanner.stop()
        flashTask?.cancel()
        flashTask = nil
        flashID = nil
    }

    func setScanning(_ scanning: Bool) {
        guard scanning != isScanning else { return }
        isScanning = scanning
        reloadScan()
    }

    func setExtraStops(_ ids: [String]) {
        guard ids != extraStops else { return }
        extraStops = ids
        reloadScan()
    }

    /// Back to home with nothing chosen, for a fresh start.
    func goHome() {
        trail = [tree.home.id]
        reloadScan()
    }

    /// Starts the ring again from north. Called whenever the level, the
    /// mode or the pointing state changes.
    func reloadScan() {
        guard isRunning, isScanning, !isPointing else {
            scanner.stop()
            return
        }
        let nodes = stopIDs.map { id -> ScanNode in
            id == CompassStop.clear
                ? .group(id, [.item(CompassStop.clearCancel), .item(CompassStop.clearConfirm)])
                : .item(id)
        }
        if handlingScanSelection {
            // `Scanner.bind` prompts the lit stop right after a selection;
            // announcing it here as well would say the first petal twice.
            let hook = scanner.onStart
            scanner.onStart = nil
            scanner.load(nodes)
            scanner.onStart = hook
        } else {
            scanner.load(nodes)
        }
    }

    /// Every switch press while this board is on screen.
    func press(_ source: SwitchSource) {
        guard isRunning else { return }
        if isPointing {
            // The head chooses among the four by pointing; its own turn
            // "presses" are the pointing itself, not a second command.
            guard source != .head else { return }
            // Any other switch is the person's one extra movement: back
            // one level, or at home, say the message.
            if isHome {
                speakMessage()
            } else {
                back(via: .touch)
            }
            return
        }
        guard isScanning else { return }
        scanner.press()
    }

    // MARK: - Choosing

    private func scanSelected(_ id: String) {
        handlingScanSelection = true
        activate(id, via: .scan)
        handlingScanSelection = false
    }

    /// Runs the stop with this id: a petal, the centre, or a chip.
    func activate(_ id: String, via source: ChoiceSource) {
        guard isRunning else { return }
        if let direction = Direction(stopID: id) {
            choose(direction, via: source)
            return
        }
        switch id {
        case CompassStop.hub:
            speakMessage()
        case CompassStop.back:
            back(via: source)
        case CompassStop.backToStart:
            backToStart(via: source)
        case CompassStop.language:
            toggleLanguage(via: source)
        case CompassStop.clearCancel:
            // The message stays. A scan has already returned to the top of
            // the ring, and its selection feedback said the press landed.
            if source != .scan { services?.feedback.back() }
        case CompassStop.clear, CompassStop.clearConfirm:
            clearMessage(via: source)
        default:
            if source != .scan { services?.feedback.select() }
            onEvent?(.extra(id))
        }
    }

    func choose(_ direction: Direction, via source: ChoiceSource) {
        guard isRunning, let services else { return }
        let choice = level.choice(direction)
        flash(choice.id)
        switch choice.action {
        case .open(let nextID):
            if source != .scan { services.feedback.enter() }
            trail.append(nextID)
            reloadScan()
            let language = services.settings.language
            announce(level.draft(language, services.settings.gender), in: language)
        case .answer(let words):
            if source == .pointing { services.feedback.select() }
            say(words)
            trail = [tree.home.id]
            reloadScan()
            onEvent?(.said(choiceID: choice.id, kept: false))
        case .sentence(let words):
            if source == .pointing { services.feedback.select() }
            keep(choice, saying: words)
            say(words)
            // Back to home: the next sentence starts from the four that
            // matter most, and Yes and No are one press away again.
            trail = [tree.home.id]
            reloadScan()
            onEvent?(.said(choiceID: choice.id, kept: true))
        }
    }

    func back(via source: ChoiceSource) {
        guard let services else { return }
        guard trail.count > 1 else {
            services.feedback.unavailable()
            return
        }
        if source != .scan { services.feedback.back() }
        trail.removeLast()
        reloadScan()
        let language = services.settings.language
        announce(level.draft(language, services.settings.gender), in: language)
    }

    /// Straight home from any depth. The message is kept, so there is
    /// nothing to confirm.
    func backToStart(via source: ChoiceSource) {
        guard let services else { return }
        guard !isHome else {
            services.feedback.unavailable()
            return
        }
        if source != .scan { services.feedback.back() }
        goHome()
        let language = services.settings.language
        announce(level.draft(language, services.settings.gender), in: language)
    }

    /// The head-only way out: `HeadPointer` calls this when a rest in the
    /// middle completes below home.
    private func restBack() {
        guard isRunning, !isHome else { return }
        back(via: .pointing)
    }

    func speakMessage() {
        guard let services else { return }
        guard !services.message.isEmpty else {
            services.feedback.unavailable()
            return
        }
        services.feedback.speak()
        services.speaker.say(services.message.words)
        onEvent?(.spokeMessage)
    }

    func toggleLanguage(via source: ChoiceSource) {
        guard let services else { return }
        services.settings.language = services.settings.language.other
        if source != .scan { services.feedback.select() }
        let language = services.settings.language
        announce(language.nativeName, in: language)
    }

    func clearMessage(via source: ChoiceSource) {
        guard let services else { return }
        services.message.clear()
        services.speaker.stop()
        if source != .scan { services.feedback.back() }
        reloadScan()
    }

    // MARK: - Helpers

    private func say(_ words: Bilingual) {
        guard let services else { return }
        services.feedback.speak()
        services.speaker.say(words)
    }

    /// Adds a finished sentence to the message. A full message drops its
    /// oldest sentence rather than refusing the newest: the newest is the
    /// one the person needs heard now.
    private func keep(_ choice: CompassChoice, saying words: Bilingual) {
        guard let message = services?.message else { return }
        let phrase = Phrase(choice.id, choice.label, says: words, symbol: choice.symbol, kind: choice.kind)
        if message.isFull {
            let kept = Array(message.phrases.suffix(message.capacity - 1))
            message.clear()
            for old in kept {
                message.add(old)
            }
        }
        message.add(phrase)
    }

    private func flash(_ id: String) {
        flashID = id
        flashTask?.cancel()
        flashTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.9))
            guard !Task.isCancelled else { return }
            self?.flashID = nil
        }
    }

    /// Words for each stop, for auditory prompts.
    func label(for id: String) -> Bilingual? {
        if let direction = Direction(stopID: id) {
            return level.choice(direction).label
        }
        switch id {
        case CompassStop.hub: return CoreCopy.speak
        case CompassStop.back: return CoreCopy.goBack
        case CompassStop.backToStart: return Copy.Board.backToStart
        case CompassStop.clear: return CoreCopy.clear
        case CompassStop.clearCancel: return CoreCopy.clearCancel
        case CompassStop.clearConfirm: return CoreCopy.clearConfirm
        case CompassStop.language:
            // Spoken in the board's own language, naming where it goes: an
            // English voice must never be handed «Українська».
            let other = services?.settings.language.other ?? .ukrainian
            return Copy.Board.switchToSpoken(other)
        default: return extraLabel(id)
        }
    }
}
