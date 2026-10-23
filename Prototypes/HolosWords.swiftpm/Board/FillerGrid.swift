import SwiftUI

/// The words that fit the open starter: two rows of four.
///
/// This is where the board offers instead of asking. After "I feel…",
/// only feelings are here; after "Call my…", only people. Eight pictures
/// to recognise, not a dictionary to search — and every one of them says
/// a whole, correct sentence.
struct FillerGrid: View {
    var isScanning = false
    var compact = false

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var board: WordsBoard { experience.board }

    var body: some View {
        let language = settings.language
        VStack(alignment: .leading, spacing: 8) {
            if !compact {
                Copy.wordsFor(board.frame.starter).text(language, settings.gender)
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(WordsTheme.secondary(contrast))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.leading, 8)
                    .accessibilityAddTraits(.isHeader)
            }
            ForEach(Array(board.fillerRows.enumerated()), id: \.offset) { index, row in
                fillerRow(index: index, row: row)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func fillerRow(index: Int, row: [Phrase]) -> some View {
        let rowID = ScanID.fillerRow(index)
        let scanner = board.scanner
        return HStack(spacing: 10) {
            ForEach(row) { phrase in
                let id = ScanID.filler(phrase.id)
                SymbolCell(
                    phrase: phrase,
                    isHighlighted: scanner.isHighlighted(id),
                    hint: Copy.finishes(phrase.speech)
                ) {
                    board.tap(id)
                }
                .guideMarker(board.target == .filler(phrase.id), language: settings.language)
            }
            if isScanning {
                BackCell(isHighlighted: scanner.isHighlighted(Scanner.backID(for: rowID))) {}
                    .frame(width: compact ? 58 : 96)
                    // Reached only by the scan, which speaks "Go back" itself.
                    .accessibilityHidden(true)
            }
        }
        .frame(maxHeight: .infinity)
        .scanRow(rowID, scanner: scanner)
    }
}

/// "Not here? Find a word" — the way out when the word is not offered.
///
/// It spans the board's full width and sits last in the scan, after the
/// words: it is the second tool, not the first thing anyone should need.
struct FindStrip: View {
    var compact = false

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var board: WordsBoard { experience.board }

    var body: some View {
        let language = settings.language
        Button {
            board.tap(ScanID.findOpen)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WordKind.question.ink)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Copy.findStripTitle.text(language)
                        .font(.system(.headline, design: .serif, weight: .bold))
                        .foregroundStyle(HolosTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !compact {
                        Copy.findStripDetail.text(language)
                            .font(.subheadline)
                            .foregroundStyle(WordsTheme.secondary(contrast))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(WordKind.question.ink)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(WordKind.question.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(WordKind.question.ink.opacity(contrast == .increased ? 1 : 0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(board.scanner.isHighlighted(ScanID.findOpen), cornerRadius: 18)
        .guideMarker(board.target == .findOpen, language: language)
        .accessibilityLabel(Copy.findWord.text(language))
        .accessibilityHint(Copy.findStripHint.text(language))
        .accessibilityInputLabels(Copy.findWord.inputLabels)
    }
}

#Preview("Words") {
    let experience = Experience()
    return VStack(spacing: 12) {
        FillerGrid(isScanning: true)
        FindStrip()
    }
    .padding()
    .frame(height: 520)
    .background(WordsTheme.paper)
    .environment(experience)
    .holos(.preview())
}
