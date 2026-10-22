import SwiftUI

/// Everything a Holos screen needs from outside itself, created once at
/// launch and handed down through the environment.
///
/// Screens read the parts with `@Environment(HolosSettings.self)` and so
/// on, or the whole bundle with `@Environment(HolosServices.self)` when
/// they need to hand it on — to `Scanner.bind(to:)` or
/// `MessageBar.perform(_:services:)`. It is `@Observable` only so the
/// environment can carry it; its own properties never change.
@MainActor
@Observable
final class HolosServices {
    let settings: HolosSettings
    let hub: SwitchHub
    let speaker: Speaker
    let feedback: Feedback
    let message: MessageBuilder

    /// - Parameter keyPrefix: Keeps this prototype's stored settings apart
    ///   from the others', e.g. `"holos.grid"`.
    init(keyPrefix: String, persistent: Bool = true) {
        let settings = HolosSettings(keyPrefix: keyPrefix, persistent: persistent)
        self.settings = settings
        hub = SwitchHub(settings: settings)
        speaker = Speaker(settings: settings)
        feedback = Feedback(settings: settings)
        message = MessageBuilder()
    }

    /// A throwaway set for SwiftUI previews: nothing is stored.
    static func preview() -> HolosServices {
        HolosServices(keyPrefix: "holos.preview", persistent: false)
    }
}

extension View {
    /// Puts every Holos service into the environment.
    func holos(_ services: HolosServices) -> some View {
        environment(services)
            .environment(services.settings)
            .environment(services.hub)
            .environment(services.speaker)
            .environment(services.feedback)
            .environment(services.message)
    }
}
