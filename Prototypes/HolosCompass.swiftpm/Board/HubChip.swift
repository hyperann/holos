import SwiftUI

/// The chips under the hub: Back (and, deeper down, Back to start) below
/// home; the other language (and, with a message, Clear) at home.
///
/// Smaller than a petal because it is used less, but never below 56 points
/// tall, and lit by the same ring as everything else.
struct HubChip: View {
    /// What the chip shows.
    let title: Bilingual
    let symbol: String
    var isLit = false
    var isGuide = false
    /// What VoiceOver calls it, when that differs from the visible title —
    /// the language chip shows «Українська» but is the "Language" control.
    var spokenTitle: Bilingual?
    var valueText: Text?
    var hint: Bilingual?
    /// 0…1 while a head resting in the middle is about to choose this chip
    /// (Back, for head pointing). A ring fills around the symbol.
    var progress: Double = 0
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        let language = settings.language
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 32, height: 32)
                    .overlay {
                        if progress > 0 {
                            // Black under yellow, like the petals' hold ring.
                            ZStack {
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(HolosTheme.keyline, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(HolosTheme.highlight, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            }
                            .rotationEffect(.degrees(-90))
                        }
                    }
                    .accessibilityHidden(true)
                title.text(language, settings.gender)
                    .font(CompassTheme.font(.title3))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .foregroundStyle(HolosTheme.ink)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 56)
            .background(WordKind.control.tint, in: shape)
            .overlay {
                shape.strokeBorder(
                    WordKind.control.ink.opacity(contrast == .increased ? 1 : 0.4),
                    lineWidth: contrast == .increased ? 3 : 1.5
                )
            }
            .overlay(alignment: .top) {
                if isGuide {
                    GuideMarker()
                        .offset(y: -16)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .scanHighlight(isLit, cornerRadius: 18)
        .accessibilityLabel((spokenTitle ?? title).text(language, settings.gender))
        .accessibilityValue(valueText ?? Text(verbatim: ""))
        .accessibilityHint(hint?.text(language) ?? Text(verbatim: ""))
        .accessibilityAddTraits(isLit ? .isSelected : [])
        .accessibilityInputLabels((spokenTitle ?? title).inputLabels)
    }
}

#Preview("Hub chips") {
    HStack(spacing: 12) {
        HubChip(title: CoreCopy.goBack, symbol: "arrow.uturn.backward", isLit: true, progress: 0.6) {}
        HubChip(title: Copy.Board.switchTo(.ukrainian), symbol: "globe", isGuide: true) {}
        HubChip(title: CoreCopy.clear, symbol: "xmark") {}
    }
    .frame(height: 64)
    .padding(30)
    .background(CompassTheme.background)
    .holos(.preview())
}
