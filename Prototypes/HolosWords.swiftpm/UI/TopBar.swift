import SwiftUI

/// The chrome every screen shares: the name, the language toggle and
/// Settings — and, on the free board, a way back into the tour.
///
/// It always sits outside the whole-screen switch area, so a carer can
/// reach Settings with a finger even while a scan is running.
struct TopBar: View {
    var showsRestart = false

    @Environment(Experience.self) private var experience
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        @Bindable var experience = experience
        let language = settings.language
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(WordKind.people.ink)
                    .accessibilityHidden(true)
                Copy.appName.text(language)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            if showsRestart {
                Button {
                    services.feedback.select()
                    experience.restart()
                } label: {
                    roundIcon("arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Copy.restart.text(language))
                .accessibilityHint(Copy.restartHint.text(language))
                .accessibilityInputLabels(Copy.restart.inputLabels)
            }

            LanguageToggle()

            Button {
                services.feedback.enter()
                experience.settingsOpen = true
            } label: {
                roundIcon("gearshape.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(CoreCopy.settingsButton.text(language))
            .accessibilityHint(CoreCopy.settingsButtonHint.text(language))
            .accessibilityInputLabels(CoreCopy.settingsButton.inputLabels)
        }
        .sheet(isPresented: $experience.settingsOpen) {
            // Re-injected: a sheet is a new presentation and should not rely
            // on inheriting the environment.
            SettingsSheet()
                .holos(services)
        }
    }

    private func roundIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title3.weight(.bold))
            .foregroundStyle(HolosTheme.ink)
            .frame(width: 48, height: 48)
            .background(WordKind.control.tint, in: Circle())
            .overlay { Circle().strokeBorder(HolosTheme.ink.opacity(0.25), lineWidth: 1) }
            .contentShape(Circle())
    }
}

#Preview("Top bar") {
    TopBar(showsRestart: true)
        .padding()
        .environment(Experience())
        .holos(.preview())
}
