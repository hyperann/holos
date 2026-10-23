import SwiftUI

/// The whole app: a top bar, and whichever step the tour is on.
struct RootView: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    @State private var showingSettings = false

    private var isScanningMode: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(showingSettings: $showingSettings)
            // One branch for every board step, so the board keeps its
            // identity — and its scan — from step 2 to the free board.
            Group {
                switch experience.step {
                case .problem:
                    ProblemStep()
                case .oneSwitch, .aphasia, .ukrainian, .free:
                    BoardStep()
                case .closing:
                    ClosingStep()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(GridTheme.paper.ignoresSafeArea())
        // Light only. The Fitzgerald tints are designed for black text on a
        // light ground; inverted they lose the contrast that makes them
        // readable from a hospital bed, and a dark board would need a second
        // clinically checked palette that this prototype does not have.
        .preferredColorScheme(.light)
        .switchKeys()
        .switchPressFlash()
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
                .holos(services)
                .preferredColorScheme(.light)
        }
        .onChange(of: isScanningMode, initial: true) {
            experience.modeIsScanning = isScanningMode
        }
        .onAppear {
            experience.start()
        }
    }
}

#Preview("Holos Grid — iPad", traits: .landscapeLeft) {
    let services = HolosServices.preview()
    let experience = Experience(services: services, persistsTourState: false)
    return RootView()
        .environment(experience)
        .holos(services)
}

#Preview("Holos Grid — free board") {
    let services = HolosServices.preview()
    let experience = Experience(services: services, persistsTourState: false)
    experience.showForPreview(.free)
    return RootView()
        .environment(experience)
        .holos(services)
}
