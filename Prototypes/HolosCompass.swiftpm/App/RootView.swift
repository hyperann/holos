import SwiftUI

/// The whole app: the top bar, and below it whichever step is current.
///
/// Each step routes the switch to itself when it appears, so only the
/// newest screen ever receives presses. Settings is a sheet; Core's sheet
/// holds every press while it is open, so a carer testing a switch there
/// can never choose something on the board underneath.
struct RootView: View {
    @Environment(HolosServices.self) private var services
    @State private var experience = Experience()
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            TopBar(step: experience.step) {
                showingSettings = true
            }
            currentStep
                .id(experience.step)
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(CompassTheme.background.ignoresSafeArea())
        .foregroundStyle(CompassTheme.text)
        .environment(experience)
        .preferredColorScheme(.dark)
        .switchKeys()
        .switchPressFlash()
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
                .holos(services)
        }
    }

    @ViewBuilder
    private var currentStep: some View {
        switch experience.step {
        case .problem:
            ProblemStep()
        case .compose:
            ComposeStep()
        case .headPoint:
            HeadPointStep()
        case .ukrainian:
            UkrainianStep()
        case .closing:
            ClosingStep()
        case .free:
            FreeBoardStep()
        }
    }
}

#Preview("Holos Compass") {
    RootView()
        .holos(.preview())
}
