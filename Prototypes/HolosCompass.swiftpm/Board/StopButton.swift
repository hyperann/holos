import SwiftUI

/// A large, plain button for the narrative steps, with the scan highlight.
///
/// Every button in the judged flow is one of these, so "lit" looks the same
/// on every screen and every target is comfortably above 44 points.
struct StopButton: View {
    let title: Bilingual
    let symbol: String
    var isLit = false
    var prominent = false
    var hint: Bilingual?
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = settings.language
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                    .accessibilityHidden(true)
                title.text(language, settings.gender)
                    .font(CompassTheme.font(.title3))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .foregroundStyle(prominent ? HolosTheme.ink : CompassTheme.text)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                prominent ? WordKind.action.tint : CompassTheme.surfaceRaised,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        prominent ? WordKind.action.ink : CompassTheme.keyline(contrast),
                        lineWidth: CompassTheme.keylineWidth(contrast)
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isLit, cornerRadius: 18)
        .accessibilityLabel(title.text(language, settings.gender))
        .accessibilityHint(hint?.text(language) ?? Text(verbatim: ""))
        .accessibilityAddTraits(isLit ? .isSelected : [])
        .accessibilityInputLabels(title.inputLabels)
    }
}

#Preview("Stop buttons") {
    VStack(spacing: 16) {
        StopButton(title: Copy.App.continueLabel, symbol: "chevron.right", isLit: true, prominent: true) {}
        StopButton(title: Copy.Closing.startAgain, symbol: "arrow.counterclockwise") {}
    }
    .padding(24)
    .background(CompassTheme.background)
    .holos(.preview())
}
