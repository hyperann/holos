import SwiftUI

/// The chrome above every screen: name, where you are in the tour, the
/// language, and Settings.
///
/// It sits outside every switch area, so a carer can always reach Settings
/// with a finger without the tap counting as the person's press. A switch
/// user reaches the language through the board's own scan instead.
struct TopBar: View {
    let step: FlowStep
    let openSettings: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        // The full bar where it fits; on a phone in portrait, the same bar
        // without the little dial and the progress dots.
        ViewThatFits(in: .horizontal) {
            bar(compact: false)
            bar(compact: true)
        }
        .foregroundStyle(CompassTheme.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func bar(compact: Bool) -> some View {
        let language = settings.language
        return HStack(spacing: compact ? 10 : 14) {
            if !compact {
                NeedleDial(target: .north)
                    .frame(width: 34, height: 34)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Copy.App.name.text(language)
                        .font(CompassTheme.font(.headline))
                    Copy.App.subtitle.text(language)
                        .font(CompassTheme.font(.headline, weight: .semibold))
                        .foregroundStyle(HolosTheme.highlight)
                }
                stepLine(language)
                    .font(CompassTheme.font(.subheadline, weight: .semibold))
                    .foregroundStyle(CompassTheme.quietText)
                    .lineLimit(compact ? 2 : 1)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityElement(children: .combine)
            if !compact, let number = step.number {
                progressDots(current: number)
            }
            Spacer(minLength: 8)
            LanguageToggle()
            Button(action: openSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(CompassTheme.text)
                    .frame(width: 52, height: 52)
                    .background(CompassTheme.surfaceRaised, in: Circle())
                    .overlay {
                        Circle().strokeBorder(CompassTheme.keyline(contrast), lineWidth: CompassTheme.keylineWidth(contrast))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(CoreCopy.settingsButton.text(language))
            .accessibilityHint(CoreCopy.settingsButtonHint.text(language))
            .accessibilityInputLabels(CoreCopy.settingsButton.inputLabels)
        }
    }

    private func stepLine(_ language: Language) -> Text {
        guard let number = step.number else {
            return step.title.text(language)
        }
        return Copy.App.stepOf(number).text(language) + Text(verbatim: " · ") + step.title.text(language)
    }

    /// Four dots, filled up to the current step. Hidden from VoiceOver:
    /// the step line already says "Step 2 of 4".
    private func progressDots(current: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(1...4, id: \.self) { index in
                Circle()
                    .fill(index <= current ? HolosTheme.highlight : CompassTheme.quietText.opacity(0.35))
                    .frame(width: 9, height: 9)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Top bar") {
    VStack {
        TopBar(step: .compose) {}
        TopBar(step: .free) {}
    }
    .background(CompassTheme.background)
    .holos(.preview())
    .preferredColorScheme(.dark)
}
