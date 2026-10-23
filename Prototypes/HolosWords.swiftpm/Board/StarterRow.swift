import SwiftUI

/// The six sentence starters, as pills, plus the language switch.
///
/// Starters are the first of the two choices: they carry the grammar, so
/// the person only has to recognise the word that finishes it. The
/// language cell lives in this row so a switch-only user can reach
/// Ukrainian from the scan, not only with a finger on the top bar.
struct StarterRow: View {
    var columns = 4
    var isScanning = false
    /// On a phone the pills drop their icons: the words need the width.
    var compact = false

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var board: WordsBoard { experience.board }

    var body: some View {
        let grid = Array(repeating: GridItem(.flexible(), spacing: 10), count: max(columns, 1))
        LazyVGrid(columns: grid, spacing: 10) {
            ForEach(Vocabulary.frames) { frame in
                chip(frame)
            }
            languageChip
            if isScanning {
                BackPill(isHighlighted: board.scanner.isHighlighted(Scanner.backID(for: ScanID.startersRow)))
            }
        }
        .scanRow(ScanID.startersRow, scanner: board.scanner)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Copy.startersRow.text(settings.language))
    }

    private func chip(_ frame: SentenceFrame) -> some View {
        let language = settings.language
        let gender = settings.gender
        let id = ScanID.starter(frame.id)
        let isOpen = board.shownFrame == frame.id
        return Button {
            board.tap(id)
        } label: {
            HStack(spacing: 8) {
                if !compact {
                    Image(systemName: frame.symbol)
                        .font(.headline)
                        .foregroundStyle(frame.kind.ink)
                        .accessibilityHidden(true)
                }
                frame.starter.text(language, gender)
                    .font(.system(.headline, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, compact ? 6 : 12)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(frame.kind.tint, in: Capsule())
            .overlay {
                // The open starter keeps a firm ink outline, so it is clear
                // whose words are showing below.
                Capsule()
                    .strokeBorder(
                        isOpen ? HolosTheme.ink : frame.kind.ink.opacity(contrast == .increased ? 1 : 0.35),
                        lineWidth: isOpen ? 3 : 1.5
                    )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .scanHighlight(board.scanner.isHighlighted(id), cornerRadius: 25)
        .guideMarker(board.target == .starter(frame.id), language: language)
        .accessibilityLabel(frame.starter.text(language, gender))
        .accessibilityHint(Copy.starterHint.text(language))
        .accessibilityAddTraits(isOpen ? .isSelected : [])
        .accessibilityInputLabels(frame.starter.inputLabels)
    }

    private var languageChip: some View {
        let language = settings.language
        return Button {
            board.tap(ScanID.language)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.headline)
                    .accessibilityHidden(true)
                // Names the language you would switch TO, in that language.
                taggedText(language.other.nativeName, language.other)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(HolosTheme.ink)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(WordKind.control.tint, in: Capsule())
            .overlay { Capsule().strokeBorder(HolosTheme.ink.opacity(0.5), lineWidth: 1.5) }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .scanHighlight(board.scanner.isHighlighted(ScanID.language), cornerRadius: 25)
        .accessibilityLabel(Copy.languageCell.text(language))
        .accessibilityValue(taggedText(language.nativeName, language))
        .accessibilityHint(CoreCopy.languageHint.text(language))
        .accessibilityInputLabels(Copy.languageCell.inputLabels)
    }
}

#Preview("Starters") {
    StarterRow(columns: 4, isScanning: true)
        .padding()
        .background(WordsTheme.paper)
        .environment(Experience())
        .holos(.preview())
}
