import SwiftUI

extension View {
    /// Makes this whole area one big switch while `isActive`.
    ///
    /// In scanning mode a touch anywhere is a press — including one that
    /// happens to land on a cell. That is deliberate: someone with poor aim
    /// should get the cell the scan lit, not the one their finger hit.
    /// Put controls that must stay tappable (Settings, the mode toggle)
    /// outside the view this is applied to.
    func switchTapArea(isActive: Bool) -> some View {
        modifier(SwitchTapAreaModifier(isActive: isActive))
    }

    /// Catches Space and Enter through SwiftUI focus, as a second route
    /// alongside `KeyboardSwitch`. Apply once, near the root.
    func switchKeys() -> some View {
        modifier(SwitchKeysModifier())
    }

    /// Flashes a ring around the screen edge on every accepted press, so
    /// the person sees that the press landed even when nothing else moves.
    func switchPressFlash() -> some View {
        modifier(PressFlashModifier())
    }
}

private struct SwitchTapAreaModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                SwitchTapLayer()
            }
        }
    }
}

/// The press lands on touch-DOWN, not on a clean tap.
///
/// A tap gesture only fires when the finger lifts within tight limits of
/// time and movement. A hand with tremor or spasticity slides, rests or
/// lingers — and every one of those would be silently dropped. Switch-
/// accessible AAC accepts on contact; so does this, once per contact.
private struct SwitchTapLayer: View {
    @Environment(SwitchHub.self) private var hub
    @GestureState private var touching = false

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($touching) { _, isTouching, _ in
                        isTouching = true
                    }
            )
            .onChange(of: touching) {
                if touching { hub.press(.tap) }
            }
            // VoiceOver and Switch Control reach the cells directly; this
            // layer is for fingers only.
            .accessibilityHidden(true)
    }
}

private struct SwitchKeysModifier: ViewModifier {
    @Environment(SwitchHub.self) private var hub
    @FocusState private var focused: Bool

    func body(content: Content) -> some View {
        content
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress(keys: [.space, .return], phases: .down) { _ in
                hub.press(.key)
                return .handled
            }
            .onAppear { focused = true }
    }
}

private struct PressFlashModifier: ViewModifier {
    @Environment(SwitchHub.self) private var hub

    func body(content: Content) -> some View {
        content
            .overlay {
                // Yellow over a black keyline, like the scan highlight: yellow
                // alone nearly vanishes on a white board.
                ZStack {
                    Rectangle()
                        .strokeBorder(HolosTheme.keyline, lineWidth: 14)
                    Rectangle()
                        .inset(by: 2)
                        .strokeBorder(HolosTheme.highlight, lineWidth: 10)
                }
                // Driven by the press count itself, so every press restarts the
                // flash cleanly. An opacity fade, not movement — fine under
                // Reduce Motion.
                .keyframeAnimator(initialValue: 0.0, trigger: hub.pressCount) { ring, opacity in
                    ring.opacity(opacity)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(0.9, duration: 0.05)
                        LinearKeyframe(0.0, duration: 0.35)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}
