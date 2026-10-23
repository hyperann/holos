import SwiftUI

/// Holos Bedside + Grid: a conversation first, and the whole board behind it.
///
/// The partner asks; the board offers only the few answers that fit the
/// question; one switch picks one; Holos says it aloud. When the answer is
/// not there, or nobody is asking, Holos Grid's whole board is one press away.
@main
struct HolosBedsideGridApp: App {
    @State private var experience = Experience(services: HolosServices(keyPrefix: "holos.bedsidegrid"))

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
