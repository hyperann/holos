import Foundation
import GameController

/// Any game controller button as a switch.
///
/// Every button counts, not just A, because the person chooses which one
/// they can reach — and adaptive controllers (big programmable buttons
/// that plug in where a gamepad would) report themselves as ordinary
/// gamepads. The system's own Home, Menu and Options buttons are left
/// alone so the controller can still leave the app.
@MainActor
final class ControllerSwitch {
    private let onPress: @MainActor @Sendable () -> Void
    private let onControllersChange: @MainActor @Sendable ([String]) -> Void
    private var observers: [NSObjectProtocol] = []

    init(
        onPress: @escaping @MainActor @Sendable () -> Void,
        onControllersChange: @escaping @MainActor @Sendable ([String]) -> Void
    ) {
        self.onPress = onPress
        self.onControllersChange = onControllersChange
    }

    func start() {
        let center = NotificationCenter.default
        for name in [Notification.Name.GCControllerDidConnect, .GCControllerDidDisconnect] {
            let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
            observers.append(observer)
        }
        refresh()
    }

    private func refresh() {
        let controllers = GCController.controllers()
        onControllersChange(controllers.map { $0.vendorName ?? "Game controller" })
        for controller in controllers {
            attach(controller)
        }
    }

    private func attach(_ controller: GCController) {
        let fire = onPress
        let systemButtons: Set<String> = [GCInputButtonHome, GCInputButtonMenu, GCInputButtonOptions]
        for (name, button) in controller.physicalInputProfile.buttons where !systemButtons.contains(name) {
            // @Sendable: called on GameController's handler queue, never
            // assumed to be the main actor.
            button.pressedChangedHandler = { @Sendable (_, _, pressed) in
                guard pressed else { return }
                Task { @MainActor in fire() }
            }
        }
    }
}
