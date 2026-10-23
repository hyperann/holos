import SwiftUI

/// One topic tab. The open topic is filled terracotta, like a tab on a paper
/// folder: you can see which board you are on from across the room.
struct TopicTab: View {
    let topic: Topic
    let isSelected: Bool
    let isHighlighted: Bool
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = settings.language
        Button(action: action) {
            // Side by side when there is room; stacked on a narrow screen.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    icon
                    topic.name.text(language)
                        .lineLimit(1)
                }
                VStack(spacing: 2) {
                    icon
                    topic.name.text(language)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                }
            }
            .font(.bedside(.headline, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(isSelected ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isSelected ? BedsideTheme.personBubble(contrast) : BedsideTheme.card,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : BedsideTheme.line(contrast), lineWidth: contrast == .increased ? 2.5 : 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isHighlighted, cornerRadius: 16)
        .accessibilityLabel(topic.name.text(language))
        .accessibilityHint(Copy.topicHint.text(language))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityInputLabels(topic.name.inputLabels)
        // A fixed-height tab cannot grow with the largest text sizes, so the
        // Large Content Viewer shows its name instead, as Core's bar does.
        .accessibilityShowsLargeContentViewer {
            Label {
                topic.name.text(language)
            } icon: {
                Image(systemName: topic.symbol)
            }
        }
    }

    private var icon: some View {
        Image(systemName: topic.symbol)
            .foregroundStyle(isSelected ? Color.white : BedsideTheme.rust)
            .accessibilityHidden(true)
    }
}

/// The language cell at the end of the topics row.
///
/// The top bar has a language toggle too, but a person who can only press
/// a switch cannot reach the top bar while the whole board is scanning.
/// This cell puts the language inside the scan, so no one needs a helper.
struct LanguageCell: View {
    let isHighlighted: Bool
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = settings.language
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.title3)
                        .foregroundStyle(BedsideTheme.rust)
                        .accessibilityHidden(true)
                    chips
                }
                chips
                VStack(spacing: 2) {
                    chip(.english)
                    chip(.ukrainian)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BedsideTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(BedsideTheme.line(contrast), lineWidth: contrast == .increased ? 2.5 : 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isHighlighted, cornerRadius: 16)
        .accessibilityLabel(CoreCopy.languageLabel.text(language))
        .accessibilityValue(taggedText(language.nativeName, language))
        .accessibilityHint(CoreCopy.languageHint.text(language))
        .accessibilityInputLabels(CoreCopy.languageLabel.inputLabels)
        .accessibilityShowsLargeContentViewer {
            Label {
                taggedText(language.nativeName, language)
            } icon: {
                Image(systemName: "globe")
            }
        }
    }

    private var chips: some View {
        HStack(spacing: 2) {
            chip(.english)
            chip(.ukrainian)
        }
    }

    private func chip(_ option: Language) -> some View {
        let isCurrent = option == settings.language
        return taggedText(option.shortName, option)
            .font(.bedside(.headline, weight: .heavy))
            .lineLimit(1)
            .foregroundStyle(isCurrent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isCurrent ? HolosTheme.ink : Color.clear, in: Capsule())
    }
}

extension View {
    /// Puts Bedside's small "This one" tag on a cell, tab or control of the
    /// whole board while `isOn`, and tells VoiceOver the same thing.
    func boardGuide(_ isOn: Bool) -> some View {
        modifier(BoardGuideModifier(isOn: isOn))
    }
}

private struct BoardGuideModifier: ViewModifier {
    let isOn: Bool
    @Environment(HolosSettings.self) private var settings

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if isOn {
                    GuideMarker(compact: true)
                        .offset(x: 6, y: -10)
                }
            }
            .accessibilityValue(isOn ? Copy.suggested.text(settings.language) : Text(verbatim: ""))
    }
}

/// How a scanned row looks: ringed when lit, outlined while its cells are
/// being scanned, dimmed while another row is — and, while the guide's next
/// stop is inside it and the scan has not entered it yet, outlined in
/// terracotta with the "This one" tag, because the next press picks the row.
///
/// The ring is the same keyline-and-yellow as `scanHighlight`, drawn
/// without its small lift: a whole row is already big enough to find, and
/// lifting a full-width row would push its ring off the screen's edges.
struct ScanRowFrame: ViewModifier {
    let rowID: String
    let scanner: Scanner
    let isScanning: Bool
    var isGuided = false

    @Environment(\.colorSchemeContrast) private var contrast

    @ViewBuilder
    func body(content: Content) -> some View {
        let lit = isScanning && scanner.isHighlighted(rowID)
        let entered = isScanning && scanner.isEntered(rowID)
        let dimmed = isScanning && !scanner.path.isEmpty && !entered
        let guided = isGuided && isScanning && !entered
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        content
            .padding(GridIDs.rowPadding)
            .background {
                shape.fill(entered ? HolosTheme.highlight.opacity(0.16) : Color.clear)
            }
            .overlay {
                if lit {
                    ZStack {
                        shape.strokeBorder(HolosTheme.keyline, lineWidth: 11)
                        shape.inset(by: 2).strokeBorder(HolosTheme.highlight, lineWidth: 7)
                    }
                    .allowsHitTesting(false)
                } else if entered {
                    shape.strokeBorder(HolosTheme.highlight, lineWidth: 4)
                        .allowsHitTesting(false)
                } else if guided {
                    shape.strokeBorder(BedsideTheme.terracotta, lineWidth: 4)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .topTrailing) {
                if guided {
                    GuideMarker()
                        .offset(x: -12, y: -14)
                }
            }
            // An opacity change, never movement: fine under Reduce Motion.
            .opacity(dimmed ? (contrast == .increased ? 0.6 : 0.45) : 1)
            .animation(.easeOut(duration: 0.15), value: dimmed)
    }
}

/// The items of the topics row, in scan order.
enum TopicsRowItem: Identifiable, Hashable {
    case topic(Topic)
    case language
    case back

    var id: String {
        switch self {
        case .topic(let topic): topic.scanID
        case .language: GridIDs.language
        case .back: "grid.topics.back"
        }
    }

    static func all(includingBack: Bool) -> [TopicsRowItem] {
        var items: [TopicsRowItem] = Topic.allCases.map { TopicsRowItem.topic($0) }
        items.append(.language)
        if includingBack {
            items.append(.back)
        }
        return items
    }
}

extension Array {
    /// Splits into runs of `size`, for wrapping a row onto two lines.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}

#Preview("Board pieces") {
    let experience = Experience.preview()
    return HStack(spacing: 12) {
        TopicTab(topic: .needs, isSelected: true, isHighlighted: false) {}
        TopicTab(topic: .family, isSelected: false, isHighlighted: true) {}
            .boardGuide(true)
        LanguageCell(isHighlighted: false) {}
    }
    .frame(height: 68)
    .padding(30)
    .background(BedsideTheme.background)
    .environment(experience)
    .holos(experience.services)
}
