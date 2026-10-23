import SwiftUI

/// A wide, plain button for the tour's own choices — Continue, Show me,
/// Keep talking. At least 64 points tall: big enough for a shaky finger,
/// and for the scan highlight to be seen from a hospital bed.
struct BigButton: View {
    let title: Bilingual
    let symbol: String
    var prominent = false
    var isHighlighted = false
    var hint: Bilingual?
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = settings.language
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3.weight(.bold))
                    .accessibilityHidden(true)
                title.text(language)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(prominent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(prominent ? HolosTheme.ink : WordKind.control.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(HolosTheme.ink.opacity(contrast == .increased ? 1 : 0.2), lineWidth: contrast == .increased ? 2 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isHighlighted, cornerRadius: 18)
        .accessibilityLabel(title.text(language))
        .accessibilityHint(hint.map { $0.text(language) } ?? Text(verbatim: ""))
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
        .accessibilityInputLabels(title.inputLabels)
    }
}

#Preview("Big buttons") {
    VStack(spacing: 16) {
        BigButton(title: Copy.continueOn, symbol: "chevron.right", prominent: true, isHighlighted: true) {}
        BigButton(title: Copy.hearAgain, symbol: "speaker.wave.2.fill") {}
    }
    .padding()
    .holos(.preview())
}
