import SwiftUI

/// Name, step, language and Settings.
///
/// It sits outside every switch tap area on purpose: a carer must always be
/// able to reach Settings or the language by touch, even while the board
/// below treats every touch as a switch press.
struct TopBar: View {
    @Binding var showingSettings: Bool

    @Environment(Experience.self) private var experience
    @Environment(Feedback.self) private var feedback
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = experience.language
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.title2)
                    .foregroundStyle(GridTheme.navy)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Copy.appName.text(language)
                        .font(GridTheme.rounded(.headline, .heavy))
                        .foregroundStyle(GridTheme.navy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Copy.stepLine(experience.step).text(language)
                        .font(GridTheme.rounded(.subheadline, .semibold))
                        .foregroundStyle(GridTheme.quietInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            if experience.step == .free {
                roundButton(symbol: "arrow.counterclockwise", label: Copy.restartTour, hint: Copy.restartTourHint) {
                    feedback.select()
                    experience.restart()
                }
            }
            LanguageToggle()
            roundButton(symbol: "gearshape.fill", label: CoreCopy.settingsButton, hint: CoreCopy.settingsButtonHint) {
                showingSettings = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func roundButton(symbol: String, label: Bilingual, hint: Bilingual, action: @escaping () -> Void) -> some View {
        let language = experience.language
        return Button(action: action) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(GridTheme.navy)
                .frame(width: 48, height: 48)
                .background(GridTheme.card, in: Circle())
                .overlay {
                    Circle().strokeBorder(contrast == .increased ? GridTheme.navy : GridTheme.line, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.text(language))
        .accessibilityHint(hint.text(language))
        .accessibilityInputLabels(label.inputLabels)
    }
}

#Preview("Top bar") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.free)
    return TopBar(showingSettings: .constant(false))
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
