import SwiftUI

/// Where the guide's tag sits inside one row of the whole board.
///
/// While scanning, the next press on the board picks a ROW, so the tag sits
/// on the row that holds the next stop until the scan is inside it, and only
/// then moves to the cell, the tab or Speak. When touching, a finger goes
/// straight to the cell, so the tag is always on the cell.
@MainActor
struct RowGuide {
    /// True when the guide's next stop is in this row.
    let holdsStop: Bool
    /// True when the tag belongs on the stop itself rather than the row.
    let tagsItem: Bool

    init(target: GuideTarget?, rowID: String, board: GridBoard, isScanning: Bool) {
        holdsStop = target.map { board.rowID(holding: $0) == rowID } ?? false
        tagsItem = holdsStop && (!isScanning || board.scanner.isEntered(rowID))
    }
}

/// Row 1: the message bar.
///
/// On a wide screen, Core's `MessageBar` draws its own ring, back cells and
/// the two-press Clear; this row adds the guide over it. On a narrow screen
/// Core's bar is wider than the screen (see `CompactMessageBar`), so the row
/// is a large copy of the sentence over the board's own compact controls,
/// ringed and dimmed like every other row.
struct MessageRow: View {
    let board: GridBoard
    let isScanning: Bool
    let metrics: BoardMetrics
    let target: GuideTarget?

    @Environment(MessageBuilder.self) private var message
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    /// Where Speak sits, measured from the bar's trailing edge: the bar's
    /// padding and its fixed-width Clear and Delete controls, plus its back
    /// control while the row is entered and the second Clear control while
    /// the Clear group is open. Kept in step with `MessageBar`.
    private static let speakOffset: CGFloat = 10 + 88 + 12 + 88 + 12
    private static let enteredExtra: CGFloat = 72 + 12
    private static let clearOpenExtra: CGFloat = 88 + 12

    var body: some View {
        let scanner = board.scanner
        let highlighted = isScanning ? scanner.highlightedID : nil
        let guide = RowGuide(target: target, rowID: MessageBar.rowID, board: board, isScanning: isScanning)
        if metrics.compact {
            VStack(spacing: 6) {
                sentenceStrip
                CompactMessageBar(highlightedID: highlighted, showsGuideOnSpeak: guide.tagsItem)
            }
            .modifier(ScanRowFrame(rowID: MessageBar.rowID, scanner: scanner, isScanning: isScanning, isGuided: guide.holdsStop))
        } else {
            wideBar(highlighted: highlighted, guide: guide)
        }
    }

    private func wideBar(highlighted: String?, guide: RowGuide) -> some View {
        let scanner = board.scanner
        let entered = highlighted.map { MessageBar.owns($0) && $0 != MessageBar.rowID } ?? false
        let clearOpen: Bool = highlighted == MessageBar.clearCancelID
            || highlighted == MessageBar.clearConfirmID
            || highlighted == Scanner.backID(for: MessageBar.clearID)
        let enteredShift: CGFloat = entered ? Self.enteredExtra : 0
        let clearShift: CGFloat = clearOpen ? Self.clearOpenExtra : 0
        let speakTrailing: CGFloat = Self.speakOffset + enteredShift + clearShift
        let dimmed = isScanning && !scanner.path.isEmpty && !scanner.isEntered(MessageBar.rowID)
        let lit = isScanning && scanner.isHighlighted(MessageBar.rowID)
        let guidesRow = guide.holdsStop && !guide.tagsItem
        return MessageBar(highlightedID: highlighted, isRowEntered: entered)
            // The row-level guide, drawn as `ScanRowFrame` draws it on the
            // other rows; the yellow ring takes over while the row is lit.
            .overlay {
                if guidesRow, !lit {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(BedsideTheme.terracotta, lineWidth: 4)
                        .allowsHitTesting(false)
                }
            }
            // On the leading side: the trailing side is where Speak's own
            // tag goes once the scan is inside.
            .overlay(alignment: .topLeading) {
                if guidesRow {
                    GuideMarker()
                        .offset(x: 12, y: -14)
                }
            }
            .overlay(alignment: .topTrailing) {
                if guide.tagsItem {
                    GuideMarker(compact: true)
                        .frame(width: 88, alignment: .trailing)
                        .padding(.trailing, speakTrailing)
                        .offset(x: 6, y: -10)
                }
            }
            // As `ScanRowFrame` dims the other rows: lighter under Increase
            // Contrast, so a row out of play is still readable.
            .opacity(dimmed ? (contrast == .increased ? 0.6 : 0.45) : 1)
    }

    /// The sentence, large, on a phone — where it is the only copy of it, so
    /// VoiceOver reads it here as Core's bar would.
    private var sentenceStrip: some View {
        let language = settings.language
        return Group {
            if message.isEmpty {
                CoreCopy.messageEmpty.text(language)
                    .foregroundStyle(BedsideTheme.softInk)
            } else {
                message.words.text(language, settings.gender)
                    .foregroundStyle(HolosTheme.ink)
            }
        }
        .font(.bedside(.title3, weight: .semibold))
        .lineLimit(2)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
        .background(BedsideTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CoreCopy.messageLabel.text(language))
        .accessibilityValue(
            message.isEmpty
                ? CoreCopy.messageEmpty.text(language)
                : message.words.text(language, settings.gender)
        )
    }
}

/// Row 2: urgent quick phrases. They speak the moment they are chosen.
struct QuickRow: View {
    let board: GridBoard
    let isScanning: Bool
    let metrics: BoardMetrics

    @Environment(SwitchHub.self) private var hub
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let scanner = board.scanner
        HStack(spacing: metrics.cellGap) {
            ForEach(BoardVocabulary.quick) { phrase in
                SymbolCell(
                    phrase: phrase,
                    isHighlighted: isScanning && scanner.isHighlighted(phrase.id),
                    hint: CoreCopy.cellHintSpeak
                ) {
                    board.tapQuick(phrase)
                }
                // A small speaker: "this one talks straight away".
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WordKind.urgent.ink)
                        .padding(12)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            if isScanning {
                BackCell(isHighlighted: scanner.isHighlighted(Scanner.backID(for: GridIDs.quickRow))) {
                    hub.press(.tap)
                }
                .frame(width: metrics.backWidth)
            }
        }
        .frame(height: metrics.quickHeight)
        .modifier(ScanRowFrame(rowID: GridIDs.quickRow, scanner: scanner, isScanning: isScanning))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Copy.quickRow.text(settings.language))
    }
}

/// Row 3: the topic tabs and the language cell. Wraps onto two lines on a
/// narrow screen, but scans as one row either way.
struct TopicsRow: View {
    let board: GridBoard
    let isScanning: Bool
    let metrics: BoardMetrics
    let target: GuideTarget?

    @Environment(SwitchHub.self) private var hub
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let items = TopicsRowItem.all(includingBack: isScanning)
        let perLine = metrics.topicsLines > 1 ? (items.count + 1) / 2 : items.count
        let lines = items.chunked(into: perLine)
        let guide = RowGuide(target: target, rowID: GridIDs.topicsRow, board: board, isScanning: isScanning)
        VStack(spacing: metrics.cellGap) {
            ForEach(0..<lines.count, id: \.self) { index in
                HStack(spacing: metrics.cellGap) {
                    ForEach(lines[index]) { item in
                        cell(for: item, guide: guide)
                    }
                }
            }
        }
        .frame(height: metrics.topicsHeight)
        .modifier(ScanRowFrame(rowID: GridIDs.topicsRow, scanner: board.scanner, isScanning: isScanning, isGuided: guide.holdsStop))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Copy.topicsRow.text(settings.language))
    }

    @ViewBuilder
    private func cell(for item: TopicsRowItem, guide: RowGuide) -> some View {
        let scanner = board.scanner
        switch item {
        case .topic(let topic):
            TopicTab(
                topic: topic,
                isSelected: board.topic == topic,
                isHighlighted: isScanning && scanner.isHighlighted(topic.scanID)
            ) {
                board.tapTopic(topic)
            }
            .boardGuide(guide.tagsItem && target == GuideTarget.topic(topic))
        case .language:
            LanguageCell(isHighlighted: isScanning && scanner.isHighlighted(GridIDs.language)) {
                board.tapLanguage()
            }
        case .back:
            BackCell(isHighlighted: scanner.isHighlighted(Scanner.backID(for: GridIDs.topicsRow))) {
                hub.press(.tap)
            }
            .frame(width: metrics.compact ? nil : metrics.backWidth)
        }
    }
}

/// The open topic's name, big, above its two rows.
struct TopicHeader: View {
    let board: GridBoard
    let metrics: BoardMetrics

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: board.topic.symbol)
                .font(metrics.compact ? Font.title3 : Font.title2)
                .foregroundStyle(BedsideTheme.rust)
                .accessibilityHidden(true)
            board.topic.name.text(settings.language)
                .font(.bedside(metrics.compact ? .title3 : .title2, weight: .bold))
                .foregroundStyle(BedsideTheme.rust)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, GridIDs.rowPadding)
        .frame(height: metrics.headerHeight)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        // Its height is fixed so the rows below never move; at the largest
        // text sizes the Large Content Viewer shows the name instead.
        .accessibilityShowsLargeContentViewer {
            Label {
                board.topic.name.text(settings.language)
            } icon: {
                Image(systemName: board.topic.symbol)
            }
        }
    }
}

/// Rows 4 and 5: five cells of the open topic each.
struct PhraseRow: View {
    let rowID: String
    let number: Int
    let phrases: [Phrase]
    let board: GridBoard
    let isScanning: Bool
    let metrics: BoardMetrics
    let target: GuideTarget?

    @Environment(SwitchHub.self) private var hub
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let scanner = board.scanner
        let guide = RowGuide(target: target, rowID: rowID, board: board, isScanning: isScanning)
        HStack(spacing: metrics.cellGap) {
            ForEach(phrases) { phrase in
                SymbolCell(phrase: phrase, isHighlighted: isScanning && scanner.isHighlighted(phrase.id)) {
                    board.tapCell(phrase)
                }
                .boardGuide(guide.tagsItem && target == GuideTarget.cell(phrase, on: board.topic))
            }
            if isScanning {
                BackCell(isHighlighted: scanner.isHighlighted(Scanner.backID(for: rowID))) {
                    hub.press(.tap)
                }
                .frame(width: metrics.backWidth)
            }
        }
        .frame(height: metrics.cellRowHeight)
        .modifier(ScanRowFrame(rowID: rowID, scanner: scanner, isScanning: isScanning, isGuided: guide.holdsStop))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Copy.topicRow(board.topic, number).text(settings.language))
    }
}

#Preview("Rows, guided") {
    let experience = Experience.preview(.conversation, boardOpen: true)
    let board = experience.board
    let metrics = BoardMetrics(size: CGSize(width: 1100, height: 760))
    return VStack(spacing: metrics.gutter) {
        MessageRow(board: board, isScanning: true, metrics: metrics, target: .speak)
        QuickRow(board: board, isScanning: true, metrics: metrics)
        TopicsRow(board: board, isScanning: true, metrics: metrics, target: board.guideTarget)
        TopicHeader(board: board, metrics: metrics)
        PhraseRow(
            rowID: GridIDs.topicRowOne, number: 1, phrases: board.firstRow,
            board: board, isScanning: true, metrics: metrics, target: board.guideTarget
        )
    }
    .padding()
    .background(BedsideTheme.background)
    .environment(experience)
    .holos(experience.services)
}
