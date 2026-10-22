import SwiftUI

/// One picture-and-word cell.
///
/// Symbol above, word below, always both: aphasia can take reading or
/// picture-naming independently, and the pair gives two ways in. The cell
/// fills whatever space its board gives it, so the board decides the size.
struct SymbolCell: View {
    let phrase: Phrase
    var isHighlighted = false
    /// What a VoiceOver user hears the cell will do.
    var hint: Bilingual = CoreCopy.cellHintTouch
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: phrase.symbol)
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(phrase.kind.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
                phrase.label.text(language, gender)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(phrase.kind.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(phrase.kind.ink.opacity(contrast == .increased ? 1 : 0.35), lineWidth: contrast == .increased ? 3 : 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isHighlighted)
        .accessibilityLabel(phrase.label.text(language, gender))
        .accessibilityHint(hint.text(language))
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
        .accessibilityInputLabels(phrase.label.inputLabels)
    }
}

/// The "go back" cell that ends every scanned row.
struct BackCell: View {
    var isHighlighted = false
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 30, weight: .bold))
                    .accessibilityHidden(true)
                CoreCopy.goBack.text(settings.language)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(WordKind.control.ink)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isHighlighted)
        .accessibilityLabel(CoreCopy.goBack.text(settings.language))
        .accessibilityHint(CoreCopy.goBackHint.text(settings.language))
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
        .accessibilityInputLabels(CoreCopy.goBack.inputLabels)
    }
}

#Preview("Cells") {
    let services = HolosServices.preview()
    HStack(spacing: 16) {
        SymbolCell(phrase: Phrase("pain", Bilingual("Pain", uk: "Біль"), symbol: "bandage.fill", kind: .urgent), isHighlighted: true) {}
        SymbolCell(phrase: Phrase("water", Bilingual("Water", uk: "Вода"), symbol: "drop.fill", kind: .thing)) {}
        BackCell {}
    }
    .frame(height: 160)
    .padding()
    .holos(services)
}
