import CoreHaptics

/// Core Haptics behind `FeedbackEvent`s.
///
/// Patterns are built once and their players rebuilt if the engine resets.
/// On hardware without haptics every call is a silent no-op — the paired
/// sound and the highlight still carry the event.
@MainActor
final class HapticPlayer {
    let supportsHaptics: Bool
    private var engine: CHHapticEngine?
    private var players: [FeedbackEvent: CHHapticPatternPlayer] = [:]

    init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            // Powers down when idle; a player wakes it on start.
            engine.isAutoShutdownEnabled = true
            // Explicitly @Sendable: Core Haptics calls this on its own queue.
            // Left unannotated, Swift 6 would infer main-actor isolation from
            // this initializer and trap on the first engine reset.
            engine.resetHandler = { @Sendable [weak self] in
                Task { @MainActor in self?.rebuildPlayers() }
            }
            self.engine = engine
            rebuildPlayers()
        } catch {
            // A failed engine behaves exactly like missing hardware.
            engine = nil
        }
    }

    func prepare() {
        try? engine?.start()
    }

    func play(_ event: FeedbackEvent) {
        guard let player = players[event] else { return }
        do {
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // One recovery attempt after a stopped engine, then give up
            // quietly — the sound and the highlight still carry the event.
            try? engine?.start()
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }

    private func rebuildPlayers() {
        players.removeAll()
        guard let engine else { return }
        for event in FeedbackEvent.allCases {
            guard let pattern = try? Self.pattern(for: event),
                  let player = try? engine.makePlayer(with: pattern)
            else { continue }
            players[event] = player
        }
    }

    private static func pattern(for event: FeedbackEvent) throws -> CHHapticPattern {
        switch event {
        case .step:
            // Light and crisp: many of these in a row must never tire.
            return try CHHapticPattern(events: [transient(at: 0, intensity: 0.42, sharpness: 0.65)], parameters: [])
        case .enter:
            return try CHHapticPattern(events: [
                transient(at: 0, intensity: 0.6, sharpness: 0.5),
                transient(at: 0.09, intensity: 0.75, sharpness: 0.6),
            ], parameters: [])
        case .select:
            // The one strong event: there is no doubt something was chosen.
            return try CHHapticPattern(events: [
                transient(at: 0, intensity: 1.0, sharpness: 0.75),
                continuous(at: 0.02, duration: 0.12, intensity: 0.5, sharpness: 0.3),
            ], parameters: [])
        case .back:
            return try CHHapticPattern(events: [
                transient(at: 0, intensity: 0.75, sharpness: 0.6),
                transient(at: 0.09, intensity: 0.45, sharpness: 0.35),
            ], parameters: [])
        case .pause:
            return try CHHapticPattern(events: [
                continuous(at: 0, duration: 0.3, intensity: 0.35, sharpness: 0.15),
            ], parameters: [])
        case .speak:
            return try CHHapticPattern(events: [
                continuous(at: 0, duration: 0.18, intensity: 0.45, sharpness: 0.25),
                transient(at: 0.18, intensity: 0.6, sharpness: 0.45),
            ], parameters: [])
        case .unavailable:
            // Low and dull: "not that", never a punishment.
            return try CHHapticPattern(events: [
                continuous(at: 0, duration: 0.22, intensity: 0.5, sharpness: 0.05),
            ], parameters: [])
        }
    }

    private static func transient(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }

    private static func continuous(
        at time: TimeInterval,
        duration: TimeInterval,
        intensity: Float,
        sharpness: Float
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time,
            duration: duration
        )
    }
}
