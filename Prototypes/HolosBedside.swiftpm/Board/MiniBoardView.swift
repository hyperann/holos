import SwiftUI

/// "Something else": a compact topic board for whatever the prediction
/// missed.
///
/// Two rows of four words per topic, scanned row first and then word —
/// the classic row-column scan, which only pays off once there are more
/// than six or so things to reach. The topics sit at the bottom like a tab
/// bar, so the scan runs top to bottom in the same order the eye does:
/// rows, then topics, then the way back.
struct MiniBoardView: View {
    let scanner: Scanner
    let isScanning: Bool
    /// Short on height (a phone in portrait): the help line goes, the tabs
    /// and back cells shrink, and the rows keep the room.
    var compact = false
    let onTap: (String) -> Void

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    /// Below this a row of word cells stops being a hand-sized target.
    private static let rowMinHeight: CGFloat = 64

    var body: some View {
        let topic = experience.conversation.miniTopic
        let guide = experience.guideID
        VStack(spacing: 12) {
            if !compact {
                Copy.miniHelp.text(settings.language)
                    .font(.bedside(.subheadline, weight: .semibold))
                    .foregroundStyle(BedsideTheme.softInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            ForEach(Array(topic.rows.enumerated()), id: \.offset) { index, row in
                rowView(index: index, phrases: row, guide: guide)
            }
            HStack(spacing: 10) {
                ForEach(MiniTopic.allCases) { option in
                    topicTab(option, isCurrent: option == topic, isGuide: guide == option.scanID)
                }
                closeButton(isGuide: guide == BoardID.miniClose)
            }
            .frame(height: compact ? 60 : 84)
        }
    }

    private func rowView(index: Int, phrases: [Phrase], guide: String?) -> some View {
        let rowID = BoardID.miniRow(index)
        let isEntered = scanner.isEntered(rowID)
        // While scanning, the next press on the guide's row picks the ROW,
        // so the marker sits on the row until the scan is inside it. A
        // finger (touch mode) goes straight to the word, so it stays there.
        let guidesRow = isScanning && !isEntered && experience.guideRowIndex == index
        let language = settings.language
        return HStack(spacing: 10) {
            ForEach(phrases) { phrase in
                let isGuide = guide == phrase.id
                SymbolCell(
                    phrase: phrase,
                    isHighlighted: scanner.isHighlighted(phrase.id),
                    hint: CoreCopy.cellHintSpeak
                ) {
                    onTap(phrase.id)
                }
                .overlay(alignment: .topTrailing) {
                    if isGuide, !guidesRow {
                        GuideMarker(compact: true)
                            .padding(6)
                    }
                }
                // The tag is hidden from VoiceOver, so the cell says it too,
                // as the main answer cells do.
                .accessibilityValue(isGuide ? Copy.suggested.text(language) : Text(""))
            }
            // The way out of a row is only needed while scanning; a finger
            // simply taps elsewhere.
            if isScanning {
                BackCell(isHighlighted: scanner.isHighlighted(Scanner.backID(for: rowID))) {}
                    .frame(maxWidth: compact ? 64 : 96)
                    .accessibilityHidden(true)
            }
        }
        .padding(8)
        .frame(minHeight: Self.rowMinHeight)
        .background(BedsideTheme.card.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            rowOutline(isEntered: isEntered, guidesRow: guidesRow)
        }
        .overlay(alignment: .topTrailing) {
            if guidesRow {
                GuideMarker()
                    .offset(x: 6, y: -12)
            }
        }
        .scanHighlight(scanner.isHighlighted(rowID), cornerRadius: 22)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text((index == 0 ? Copy.topRow : Copy.bottomRow).spoken(language)))
    }

    /// Which row the scan is inside, and which one the guide points to.
    @ViewBuilder
    private func rowOutline(isEntered: Bool, guidesRow: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        if isEntered {
            // Drawn like Core's highlight, yellow between black keylines:
            // yellow alone on cream is about 1.4:1 and all but vanishes.
            ZStack {
                shape.strokeBorder(HolosTheme.keyline, lineWidth: 8)
                shape.inset(by: 2).strokeBorder(HolosTheme.highlight, lineWidth: 4)
            }
        } else if guidesRow {
            shape.strokeBorder(BedsideTheme.terracotta, lineWidth: 4)
        } else {
            shape.strokeBorder(BedsideTheme.line(contrast).opacity(0.5), lineWidth: 1)
        }
    }

    private func topicTab(_ topic: MiniTopic, isCurrent: Bool, isGuide: Bool) -> some View {
        Button {
            onTap(topic.scanID)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: topic.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .accessibilityHidden(true)
                topic.title.text(settings.language)
                    .font(.bedside(.title3, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(isCurrent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isCurrent ? BedsideTheme.personBubble(contrast) : BedsideTheme.card,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isGuide ? BedsideTheme.terracotta : BedsideTheme.line(contrast), lineWidth: isGuide ? 4 : 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if isGuide {
                GuideMarker(compact: true)
                    .offset(x: 4, y: -10)
            }
        }
        .scanHighlight(scanner.isHighlighted(topic.scanID), cornerRadius: 18)
        .accessibilityLabel(topic.title.text(settings.language))
        .accessibilityHint(Copy.topicHint.text(settings.language))
        .accessibilityValue(isGuide ? Copy.suggested.text(settings.language) : Text(""))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func closeButton(isGuide: Bool) -> some View {
        Button {
            onTap(BoardID.miniClose)
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(WordKind.control.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(isGuide ? BedsideTheme.terracotta : Color.clear, lineWidth: 4)
                }
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 110)
        .scanHighlight(scanner.isHighlighted(BoardID.miniClose), cornerRadius: 18)
        .accessibilityLabel(Copy.backToAnswers.text(settings.language))
        .accessibilityHint(Copy.backToAnswersHint.text(settings.language))
        .accessibilityValue(isGuide ? Copy.suggested.text(settings.language) : Text(""))
    }
}

#Preview("Something else") {
    let experience = Experience.preview()
    experience.conversation.openMiniBoard()
    return MiniBoardView(scanner: Scanner(), isScanning: true) { _ in }
        .padding()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}

#Preview("Something else, phone") {
    let experience = Experience.preview()
    experience.conversation.openMiniBoard()
    return MiniBoardView(scanner: Scanner(), isScanning: true, compact: true) { _ in }
        .frame(height: 260)
        .padding()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
