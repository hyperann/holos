import Foundation
import Observation

/// What the person feels and hears as they scan and choose.
///
/// Each event pairs a Core Haptics pattern with a short synthesised sound,
/// and the scan highlight is always the visual third. On an iPad — no
/// Taptic Engine — the sound carries what the haptic would have, so the
/// experience is complete on every device. Settings can switch either
/// channel off; the highlight can never be switched off.
@MainActor
@Observable
final class Feedback {
    @ObservationIgnored private let settings: HolosSettings
    @ObservationIgnored private let haptics = HapticPlayer()
    @ObservationIgnored private let tones = TonePlayer()

    init(settings: HolosSettings) {
        self.settings = settings
    }

    /// True on hardware that can vibrate. Settings uses it to explain why
    /// the vibration switch does nothing on most iPads.
    var deviceCanVibrate: Bool { haptics.supportsHaptics }

    /// Warms both engines so the first tick has no start-up delay.
    func prepare() {
        haptics.prepare()
        tones.prepare()
    }

    /// The highlight moved on: one light tick.
    func step() { play(.step) }
    /// A group opened: two quick taps, "you are inside now".
    func enter() { play(.enter) }
    /// Something was chosen: one firm, bright confirmation.
    func select() { play(.select) }
    /// Went back a level: a falling pair, the mirror of `enter`.
    func back() { play(.back) }
    /// The scan stopped to rest: a soft, long settle.
    func pause() { play(.pause) }
    /// A message is about to be spoken: a short swell.
    func speak() { play(.speak) }
    /// Something did not work (camera refused, nothing to speak).
    func unavailable() { play(.unavailable) }

    private func play(_ event: FeedbackEvent) {
        if settings.hapticsOn { haptics.play(event) }
        if settings.soundOn { tones.play(event) }
    }
}

/// The vocabulary of feelings, shared by the haptic and sound players.
enum FeedbackEvent: CaseIterable, Sendable {
    case step
    case enter
    case select
    case back
    case pause
    case speak
    case unavailable
}
