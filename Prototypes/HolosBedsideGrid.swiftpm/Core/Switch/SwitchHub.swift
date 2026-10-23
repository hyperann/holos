import Foundation
import Observation

/// The single place every input turns into "the switch was pressed".
///
/// Screens never listen to a keyboard, a controller or a camera directly.
/// They call `route(_:)` once to say where presses should go, and the hub
/// does the rest: it filters out presses that come too close together
/// (a tremor, a bouncing switch, or the same key arriving by two routes),
/// counts every accepted press so the screen can flash in answer, and
/// remembers which input it came from.
@MainActor
@Observable
final class SwitchHub {
    /// Increments on every accepted press. Views watch it to flash.
    private(set) var pressCount = 0
    private(set) var lastSource: SwitchSource?
    private(set) var keyboardConnected = false
    private(set) var controllerNames: [String] = []
    let head: HeadSwitch

    @ObservationIgnored private let settings: HolosSettings
    @ObservationIgnored private var handler: ((SwitchSource) -> Void)?
    @ObservationIgnored private var lastAccepted: ContinuousClock.Instant?
    @ObservationIgnored private let clock = ContinuousClock()
    @ObservationIgnored private var keyboard: KeyboardSwitch?
    @ObservationIgnored private var controllers: ControllerSwitch?
    @ObservationIgnored private var suspensions = 0

    /// True while something on top — the Settings sheet — holds presses.
    /// Presses are still counted and flashed, so a carer testing a switch
    /// in Settings sees it work, but they reach no board: a test press must
    /// never add a word or clear a message on the screen underneath.
    var isSuspended: Bool { suspensions > 0 }

    init(settings: HolosSettings) {
        self.settings = settings
        head = HeadSwitch(settings: settings)
        head.onTrigger = { [weak self] in
            self?.press(.head)
        }
    }

    /// Starts listening for keyboards and game controllers. Safe to call
    /// more than once; only the first call does anything.
    func start() {
        guard keyboard == nil else { return }
        let keyboard = KeyboardSwitch(
            onPress: { [weak self] in self?.press(.key) },
            onConnectionChange: { [weak self] connected in self?.keyboardConnected = connected }
        )
        let controllers = ControllerSwitch(
            onPress: { [weak self] in self?.press(.controller) },
            onControllersChange: { [weak self] names in self?.controllerNames = names }
        )
        self.keyboard = keyboard
        self.controllers = controllers
        keyboard.start()
        controllers.start()
    }

    /// Sends every accepted press to `handler` until the next `route` call.
    /// A screen calls this when it appears; the newest screen wins.
    func route(_ handler: @escaping (SwitchSource) -> Void) {
        self.handler = handler
    }

    /// Presses are still counted and flashed, but go nowhere.
    func unroute() {
        handler = nil
    }

    /// Holds delivery until a matching `resume()`. Counted, so two things
    /// holding presses at once cannot release each other early.
    func suspend() {
        suspensions += 1
    }

    func resume() {
        suspensions = max(0, suspensions - 1)
    }

    /// Every input calls this. So can a screen's own big on-screen switch.
    func press(_ source: SwitchSource) {
        let now = clock.now
        if let lastAccepted, lastAccepted.duration(to: now) < .seconds(settings.pressGap) {
            return
        }
        lastAccepted = now
        pressCount += 1
        lastSource = source
        guard !isSuspended else { return }
        handler?(source)
    }
}
