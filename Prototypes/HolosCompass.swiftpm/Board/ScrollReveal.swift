import SwiftUI

extension ScrollViewProxy {
    /// Brings `id` into view: a short glide, or a jump under Reduce Motion.
    ///
    /// In scanning mode the whole screen is the switch, so a finger can
    /// never scroll a page. A page that runs past the bottom of a phone has
    /// to bring the lit control (or the line that matters) to the eye by
    /// itself — otherwise the person would be choosing blind.
    @MainActor
    func reveal<ID: Hashable>(_ id: ID, anchor: UnitPoint, reduceMotion: Bool) {
        if reduceMotion {
            scrollTo(id, anchor: anchor)
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                scrollTo(id, anchor: anchor)
            }
        }
    }
}
