import SwiftUI

/// Step 3's optional coda, about 10 seconds to skip, 20 to try: the same
/// switch, with no hands.
///
/// Core's shared panel does the work — camera off until asked for, Skip lit
/// first, a held head turn counts as a press. While it is on screen it owns
/// switch routing; when it finishes, the tour moves on and the next screen
/// routes presses to its own scanner as it appears.
struct HeadTryStep: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.colorSchemeContrast) private var contrast

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    /// "Skip is lit first" is only true while scanning; in touch mode, and
    /// under VoiceOver, nothing is lit.
    private var footnote: Bilingual {
        isScanning ? Copy.headFoot : Copy.headFootTouch
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
                .padding(.horizontal, 20)
                .padding(.top, 12)
            VStack(alignment: .leading, spacing: 18) {
                StepKicker(part: 3, title: Copy.headLead)
                HeadTryPanel {
                    finish()
                }
                footnote.text(settings.language)
                    .font(.footnote)
                    .foregroundStyle(WordsTheme.secondary(contrast))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 640)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The whole page is the switch, not only the panel: a press
            // anywhere reaches the panel's own scan.
            .switchTapArea(isActive: isScanning)
        }
        // The panel is not scrollable (its switch area would swallow the
        // scroll), so the largest text sizes are held at a size it fits.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func finish() {
        // Only once, even if a head turn and a press land together.
        guard experience.step == .headTry else { return }
        experience.advance()
    }
}

#Preview("Step 3 — head turn") {
    HeadTryStep()
        .environment(Experience())
        .holos(.preview())
}
