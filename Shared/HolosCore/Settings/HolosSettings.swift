import Foundation
import Observation

/// How the person picks a cell.
enum AccessMode: String, CaseIterable, Identifiable, Sendable {
    /// Cells light up in turn; one press picks the lit one.
    case scanning
    /// Tap the cell you want. For anyone who can aim a finger.
    case touch

    var id: String { rawValue }
}

/// Everything a person, carer or therapist can tune.
///
/// Stored on the device only (UserDefaults), never synced, never sent:
/// there is no account to sync to. Head control is the one switch that is
/// deliberately NOT remembered — the camera should only ever turn on
/// because someone asked for it in this session.
@MainActor
@Observable
final class HolosSettings {
    var language: Language { didSet { store(language.rawValue, .language) } }
    var gender: SpeakerGender { didSet { store(gender.rawValue, .gender) } }
    var accessMode: AccessMode { didSet { store(accessMode.rawValue, .accessMode) } }
    /// Seconds each item stays lit while scanning.
    var scanInterval: Double { didSet { store(scanInterval, .scanInterval) } }
    /// Seconds after an accepted press during which further presses are
    /// ignored. A tremor or a bouncing switch should not select twice.
    var pressGap: Double { didSet { store(pressGap, .pressGap) } }
    /// Speak each lit item quietly as the scan reaches it — auditory
    /// scanning, for people who cannot easily see or read the board.
    var auditoryPrompts: Bool { didSet { store(auditoryPrompts, .auditoryPrompts) } }
    var hapticsOn: Bool { didSet { store(hapticsOn, .haptics) } }
    var soundOn: Bool { didSet { store(soundOn, .sound) } }
    /// 0.6…1.2 of the system's default speaking rate.
    var speechRate: Double { didSet { store(speechRate, .speechRate) } }
    /// Session-only, see the type comment.
    var headSwitchOn = false
    /// How far the head must turn, in degrees, to count as a press.
    var headTurnDegrees: Double { didSet { store(headTurnDegrees, .headTurnDegrees) } }
    /// How long the turn must be held, in seconds. Long enough that
    /// glancing at a visitor is not a press; short enough not to tire.
    var headHoldSeconds: Double { didSet { store(headHoldSeconds, .headHoldSeconds) } }

    static let scanIntervalRange: ClosedRange<Double> = 0.6...4.0
    static let pressGapRange: ClosedRange<Double> = 0.15...1.5
    static let speechRateRange: ClosedRange<Double> = 0.6...1.2
    static let headTurnRange: ClosedRange<Double> = 8...35
    static let headHoldRange: ClosedRange<Double> = 0.2...1.5

    private enum Key: String {
        case language, gender, accessMode, scanInterval, pressGap, auditoryPrompts
        case haptics, sound, speechRate, headTurnDegrees, headHoldSeconds
    }

    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let prefix: String

    /// - Parameters:
    ///   - keyPrefix: Keeps each prototype's settings apart.
    ///   - persistent: `false` for previews: nothing is read or written.
    init(keyPrefix: String, persistent: Bool = true) {
        let defaults: UserDefaults? = persistent ? .standard : nil
        self.defaults = defaults
        prefix = keyPrefix
        func value(_ key: Key) -> Any? { defaults?.object(forKey: "\(keyPrefix).\(key.rawValue)") }

        language = (value(.language) as? String).flatMap(Language.init(rawValue:)) ?? .english
        gender = (value(.gender) as? String).flatMap(SpeakerGender.init(rawValue:)) ?? .masculine
        accessMode = (value(.accessMode) as? String).flatMap(AccessMode.init(rawValue:)) ?? .scanning
        scanInterval = value(.scanInterval) as? Double ?? 1.4
        pressGap = value(.pressGap) as? Double ?? 0.3
        auditoryPrompts = value(.auditoryPrompts) as? Bool ?? false
        hapticsOn = value(.haptics) as? Bool ?? true
        soundOn = value(.sound) as? Bool ?? true
        speechRate = value(.speechRate) as? Double ?? 0.9
        headTurnDegrees = value(.headTurnDegrees) as? Double ?? 18
        headHoldSeconds = value(.headHoldSeconds) as? Double ?? 0.4
    }

    /// Back to the shipped defaults. Language is kept: resetting timing
    /// should never also take away someone's language.
    func resetToDefaults() {
        gender = .masculine
        accessMode = .scanning
        scanInterval = 1.4
        pressGap = 0.3
        auditoryPrompts = false
        hapticsOn = true
        soundOn = true
        speechRate = 0.9
        headTurnDegrees = 18
        headHoldSeconds = 0.4
    }

    /// The mode actually in force. When iOS's own VoiceOver or Switch
    /// Control is running, Holos steps aside: those tools drive the cells
    /// directly, and a second scanner running underneath would fight them.
    func effectiveMode(voiceOver: Bool, switchControl: Bool) -> AccessMode {
        voiceOver || switchControl ? .touch : accessMode
    }

    private func store(_ value: Any, _ key: Key) {
        defaults?.set(value, forKey: "\(prefix).\(key.rawValue)")
    }
}
