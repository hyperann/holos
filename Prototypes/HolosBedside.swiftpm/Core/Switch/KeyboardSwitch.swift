import Foundation
import GameController

/// Space and Enter as a switch.
///
/// Most commercial switch interfaces — the small boxes a big round switch
/// plugs into — present themselves to iPadOS and macOS as a keyboard that
/// types a space or an Enter. Reading the keyboard through GameController
/// rather than SwiftUI focus means the press lands whatever has focus: a
/// switch user cannot be asked to Tab to the right control first.
///
/// `View.switchKeys()` listens through SwiftUI focus as a second route;
/// when both catch the same key, the hub's press gap keeps it to one press.
@MainActor
final class KeyboardSwitch {
    private let onPress: @MainActor @Sendable () -> Void
    private let onConnectionChange: @MainActor @Sendable (Bool) -> Void
    private var observers: [NSObjectProtocol] = []

    init(
        onPress: @escaping @MainActor @Sendable () -> Void,
        onConnectionChange: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        self.onPress = onPress
        self.onConnectionChange = onConnectionChange
    }

    func start() {
        let center = NotificationCenter.default
        for name in [Notification.Name.GCKeyboardDidConnect, .GCKeyboardDidDisconnect] {
            let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.attach() }
            }
            observers.append(observer)
        }
        attach()
    }

    private func attach() {
        let keyboard = GCKeyboard.coalesced
        onConnectionChange(keyboard != nil)
        guard let input = keyboard?.keyboardInput else { return }
        let fire = onPress
        // @Sendable so the handler never inherits main-actor isolation from
        // here: GameController calls it on its own handler queue.
        input.keyChangedHandler = { @Sendable (_, _, keyCode, pressed) in
            guard pressed,
                  keyCode == .spacebar || keyCode == .returnOrEnter || keyCode == .keypadEnter
            else { return }
            Task { @MainActor in fire() }
        }
    }
}
