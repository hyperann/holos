import AVFoundation
import Observation

/// The person's voice: speaks messages aloud in Ukrainian or English.
///
/// Everything happens on the device through `AVSpeechSynthesizer`; no
/// text ever leaves it. Two rules shape this type:
/// - **Never speak Ukrainian through an English voice.** That is not an
///   accent, it is noise. If no Ukrainian voice is installed, Holos says
///   the English version instead and the screen explains how to add the
///   voice — the Ukrainian text stays on the board either way.
/// - **A message is never cut off by a scanning prompt.** Prompts are
///   quiet, quick, and wait their turn; messages always speak at once.
@MainActor
@Observable
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    private enum Kind {
        case message
        case prompt
    }

    /// True while a message (not a prompt) is being spoken.
    private(set) var isSpeaking = false
    /// The message being spoken, so a screen can show it large.
    private(set) var currentText: String?
    /// True when Ukrainian was asked for but there is no Ukrainian voice.
    /// Screens show `VoiceNotice` while this is set.
    private(set) var fellBackToEnglish = false
    private(set) var hasUkrainianVoice = false
    /// True while a scanning prompt is being spoken. Not observed: only the
    /// scanner reads it, to hold the highlight until the prompt is heard.
    @ObservationIgnored private(set) var isPrompting = false
    /// Called when a message (not a prompt) finishes on its own. The scan
    /// uses it to announce the item lit while the message was speaking.
    @ObservationIgnored var onMessageFinished: (() -> Void)?
    @ObservationIgnored private var currentPromptText: String?

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private let settings: HolosSettings
    @ObservationIgnored private var currentUtterance: ObjectIdentifier?
    @ObservationIgnored private var currentKind: Kind?

    init(settings: HolosSettings) {
        self.settings = settings
        super.init()
        synthesizer.delegate = self
        AudioSession.activate()
        refreshVoices()
    }

    /// Re-checks which voices are installed — the person may have just
    /// downloaded one in Settings and come back.
    func refreshVoices() {
        hasUkrainianVoice = Self.voice(for: .ukrainian) != nil
    }

    // MARK: - Speaking

    /// Speaks `words` in the chosen language and gender, or in English if
    /// that language has no voice on this device.
    func say(_ words: Bilingual) {
        let language = settings.language
        if Self.voice(for: language) != nil {
            fellBackToEnglish = false
            speak(words(language, settings.gender), in: language, kind: .message)
        } else {
            fellBackToEnglish = language != .english
            speak(words(.english), in: .english, kind: .message)
        }
    }

    /// Speaks text that is already in one language — used for lines that
    /// are not phrases, such as a demo character's question.
    func say(_ text: String, in language: Language) {
        guard Self.voice(for: language) != nil else {
            fellBackToEnglish = language != .english
            return
        }
        speak(text, in: language, kind: .message)
    }

    /// A quiet, quick reading of the item the scanner has just lit. Skipped
    /// while a message is speaking, so the person's words are never cut off.
    func prompt(_ words: Bilingual) {
        // Our own flag, set the moment a message starts — not the
        // synthesizer's, which can lag a message that has only just begun.
        if currentKind == .message { return }
        let language = Self.voice(for: settings.language) != nil ? settings.language : .english
        let text = words(language, settings.gender)
        // The same item announced twice in a row (a board reloaded by its own
        // selection, say) is said once.
        if currentKind == .prompt, currentPromptText == text { return }
        speak(text, in: language, kind: .prompt)
        currentPromptText = text
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        markFinished()
    }

    private func speak(_ text: String, in language: Language, kind: Kind) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = Self.voice(for: language)
        let rate = Float(settings.speechRate) * (kind == .prompt ? 1.15 : 1)
        utterance.rate = min(max(AVSpeechUtteranceDefaultSpeechRate * rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.volume = kind == .prompt ? 0.6 : 1
        currentUtterance = ObjectIdentifier(utterance)
        currentKind = kind
        isPrompting = kind == .prompt
        currentPromptText = nil
        if kind == .message {
            isSpeaking = true
            currentText = trimmed
        }
        synthesizer.speak(utterance)
    }

    private func markFinished() {
        currentUtterance = nil
        currentKind = nil
        isPrompting = false
        currentPromptText = nil
        isSpeaking = false
        currentText = nil
    }

    private func utteranceEnded(_ id: ObjectIdentifier) {
        // A cancelled utterance reports in after its replacement has
        // started; only the current one may clear the state.
        guard id == currentUtterance else { return }
        let finishedMessage = currentKind == .message
        markFinished()
        if finishedMessage { onMessageFinished?() }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceEnded(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceEnded(id) }
    }

    // MARK: - Voices

    /// The best installed voice for `language`, or nil if there is none.
    ///
    /// Novelty voices (the bubbling and whispering ones) and Personal Voice
    /// (which needs its own permission) are never picked: this is someone's
    /// everyday voice. Among the rest, a voice from the expected region
    /// wins, then the highest quality.
    static func voice(for language: Language) -> AVSpeechSynthesisVoice? {
        let preferredTag = preferredTag(for: language)
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.lowercased().hasPrefix(language.rawValue)
                && !voice.voiceTraits.contains(.isNoveltyVoice)
                && !voice.voiceTraits.contains(.isPersonalVoice)
        }
        return candidates.max { lhs, rhs in
            score(lhs, preferredTag: preferredTag) < score(rhs, preferredTag: preferredTag)
        }
    }

    private static func preferredTag(for language: Language) -> String {
        switch language {
        case .ukrainian:
            return "uk-ua"
        case .english:
            let current = AVSpeechSynthesisVoice.currentLanguageCode().lowercased()
            return current.hasPrefix("en") ? current : "en-us"
        }
    }

    private static func score(_ voice: AVSpeechSynthesisVoice, preferredTag: String) -> Int {
        let regionMatch = voice.language.lowercased() == preferredTag ? 10 : 0
        return regionMatch + voice.quality.rawValue
    }
}
