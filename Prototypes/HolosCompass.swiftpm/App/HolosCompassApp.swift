import SwiftUI

/// Holos Compass: every screen offers at most four choices, at the four
/// points of a compass, so one switch — or a head that can point — can say
/// a whole sentence.
@main
struct HolosCompassApp: App {
    /// Created once. Every screen reads it from the environment.
    @State private var services = HolosServices(keyPrefix: "holos.compass")

    var body: some Scene {
        WindowGroup {
            RootView()
                .holos(services)
                .onAppear {
                    services.hub.start()
                    services.feedback.prepare()
                }
        }
    }
}
