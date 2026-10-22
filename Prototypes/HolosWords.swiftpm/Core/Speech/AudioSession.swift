import AVFoundation

/// The app's one audio-session decision.
///
/// `.playback`, not `.ambient`: the ringer switch must never mute someone's
/// voice. A phone on silent in a quiet ward is exactly when a person most
/// needs to be heard. `.mixWithOthers` keeps a carer's music or a TV from
/// being stopped dead by every click.
enum AudioSession {
    @MainActor
    static func activate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
