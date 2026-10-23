import SwiftUI

/// Holos Bedside: a conversation, not a keyboard.
///
/// The partner asks; the board offers only the few answers that fit the
/// question; one switch picks one; Holos says it aloud.
@main
struct HolosBedsideApp: App {
    @State private var experience = Experience(services: HolosServices(keyPrefix: "holos.bedside"))

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(experience)
                .holos(experience.services)
                .onAppear {
                    experience.services.hub.start()
                    experience.services.feedback.prepare()
                }
        }
    }
}
