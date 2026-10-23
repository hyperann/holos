import SwiftUI

/// Holos Words: an AAC board built for anomia — knowing what you mean
/// while the word will not come.
@main
struct HolosWordsApp: App {
    @State private var services = HolosServices(keyPrefix: "holos.words")
    @State private var experience = Experience()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(experience)
                .holos(services)
                .onAppear {
                    services.hub.start()
                    services.feedback.prepare()
                }
        }
    }
}
