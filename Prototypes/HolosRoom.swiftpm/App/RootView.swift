import SwiftUI

/// One screen for the whole experience: the room in the middle, the story
/// on cards over it, the controls that must always be reachable on top.
///
/// In scanning mode every touch is a press — on the room, the chips, the
/// message, the cards and the top bar's words — except Settings and the
/// language toggle, which stay tappable for a carer. The board and each
/// card carry their own switch area, so a card's long text can still be
/// scrolled.
struct RootView: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showsSettings = false

    /// Scanning unless the person chose touch — or VoiceOver or Switch
    /// Control is running, which drive the board themselves.
    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        GeometryReader { geo in
            // Below this width the ring of phrases moves out of the picture
            // into a sheet underneath, where its words can stay large.
            let isNarrow = geo.size.width < 640
            VStack(spacing: isNarrow ? 10 : 14) {
                TopBar(isNarrow: isNarrow) {
                    showsSettings = true
                }
                stage(isNarrow: isNarrow)
            }
            .padding(.horizontal, isNarrow ? 12 : 22)
            .padding(.vertical, isNarrow ? 8 : 14)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(RoomTheme.backdrop(contrast).ignoresSafeArea())
        .switchKeys()
        .switchPressFlash()
        // SettingsSheet holds the switch hub while it is open, so the room
        // underneath waits exactly where it was.
        .sheet(isPresented: $showsSettings) {
            SettingsSheet()
        }
        .onAppear {
            experience.start(isScanning: isScanning)
        }
        .onChange(of: isScanning) {
            experience.setScanning(isScanning)
        }
        .preferredColorScheme(.dark)
    }

    private func stage(isNarrow: Bool) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 10) {
                // The room keeps a floor, so on a small phone at a large text
                // size it can shrink but never vanish.
                RoomCanvas(isNarrow: isNarrow)
                    .frame(minHeight: 140)
                    .layoutPriority(1)
                // While a card is up it speaks for the story (the Ukrainian
                // card carries its own notice), so this one waits.
                if experience.boardMode != .inert {
                    VoiceNotice()
                }
                if isNarrow, !experience.ringItems.isEmpty {
                    // A phone has no height to spare: the open ring takes the
                    // chips' and message's place instead of pushing them off
                    // screen. Nothing is lost — while a ring is open the scan
                    // is inside it, and a finger closes it with "Go back".
                    RingSheet()
                } else {
                    BottomBar(isNarrow: isNarrow)
                }
            }
            // On a phone the ring sheet slides in where the bar was.
            .animation(
                reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.34, dampingFraction: 0.82),
                value: experience.ringItems.map(\.id)
            )
            .switchTapArea(isActive: isScanning)
            .accessibilityElement(children: .contain)
            // The card goes first for VoiceOver: while one is up it is the
            // only thing on screen that can be used.
            StageOverlay(isNarrow: isNarrow)
                .accessibilityElement(children: .contain)
                .accessibilitySortPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Holos Room — iPad") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return RootView()
        .holos(services)
        .environment(experience)
}

#Preview("Holos Room — free room") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return RootView()
        .holos(services)
        .environment(experience)
        .onAppear {
            // Started first, so RootView's own start does not rewind it.
            experience.start(isScanning: true)
            experience.go(to: .free)
        }
}
