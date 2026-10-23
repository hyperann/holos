import SwiftUI

/// Holos Room: the board is a room.
///
/// Instead of a grid of cells, the person looks at a familiar place — a
/// hospital ward, their own living room — and a light moves from object to
/// object. One press opens the bed, the window, the family photo; the
/// sentences that belong there bloom around it. The room is the memory cue.
@main
struct HolosRoomApp: App {
    @State private var services: HolosServices
    @State private var experience: Experience

    init() {
        // Made together, because the story needs the same services the
        // views use: one voice, one switch hub, one message.
        let services = HolosServices(keyPrefix: "holos.room")
        _services = State(initialValue: services)
        _experience = State(initialValue: Experience(services: services))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .holos(services)
                .environment(experience)
                .onAppear {
                    services.hub.start()
                    services.feedback.prepare()
                }
        }
    }
}
