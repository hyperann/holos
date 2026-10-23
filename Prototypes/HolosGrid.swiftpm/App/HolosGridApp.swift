import SwiftUI

/// Holos Grid: the board as the description specifies it — a classic
/// aphasia-friendly topic grid with row–column scanning, done carefully.
/// It is the baseline the other four prototypes are measured against.
@main
struct HolosGridApp: App {
    @State private var services: HolosServices
    @State private var experience: Experience

    init() {
        // Built together, because the tour drives the same services the
        // board speaks through.
        let services = HolosServices(keyPrefix: "holos.grid")
        _services = State(initialValue: services)
        _experience = State(initialValue: Experience(services: services))
    }

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
