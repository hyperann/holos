import SwiftUI

/// How a scanned row looks: a sheet of slightly darker paper, ringed when
/// the scan lights it, outlined while the scan is inside it — and faded
/// while the scan is inside a different row, so the eye goes straight to
/// the row in play.
private struct ScanRowStyle: ViewModifier {
    let rowID: String
    let scanner: Scanner

    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let entered = scanner.isEntered(rowID)
        let elsewhere = !scanner.path.isEmpty && !entered
        content
            .padding(6)
            .background(WordsTheme.paperDeep.opacity(0.7), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        entered ? HolosTheme.highlight : WordsTheme.rule.opacity(contrast == .increased ? 1 : 0.45),
                        lineWidth: entered ? 4 : 1
                    )
            }
            .scanHighlight(scanner.isHighlighted(rowID), cornerRadius: 24)
            .opacity(elsewhere ? (contrast == .increased ? 0.6 : 0.45) : 1)
    }
}

extension View {
    func scanRow(_ rowID: String, scanner: Scanner) -> some View {
        modifier(ScanRowStyle(rowID: rowID, scanner: scanner))
    }
}

/// The "go back" cell at the end of a pill-shaped row. Only drawn while
/// scanning: touch users never need it, and it would only take room.
struct BackPill: View {
    var isHighlighted = false

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.uturn.backward")
                .font(.headline.weight(.bold))
            CoreCopy.goBack.text(settings.language)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(WordKind.control.ink)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
        .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .scanHighlight(isHighlighted, cornerRadius: 25)
        // Reached only by the scan, which speaks "Go back" itself.
        .accessibilityHidden(true)
    }
}

#Preview("Scanned row") {
    let scanner = Scanner()
    return HStack {
        Text(verbatim: "Row content")
            .frame(maxWidth: .infinity, minHeight: 60)
        BackPill(isHighlighted: true)
            .frame(width: 110)
    }
    .scanRow("row", scanner: scanner)
    .padding()
    .holos(.preview())
}
