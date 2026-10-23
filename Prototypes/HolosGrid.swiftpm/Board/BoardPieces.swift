import SwiftUI

/// One topic tab. The open topic is filled navy, like a tab on a paper
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
            .font(GridTheme.rounded(.headline))
            .multilineTextAlignment(.center)
            .foregroundStyle(isSelected ? Color.white : GridTheme.navy)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? GridTheme.navy : GridTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(GridTheme.navy.opacity(contrast == .increased ? 1 : 0.35), lineWidth: contrast == .increased ? 3 : 1.5)
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
            .accessibilityHidden(true)
    }
}

/// The language cell at the end of the topics row.
///
/// The top bar has a language toggle too, but a person who can only press
/// a switch cannot reach the top bar. This cell puts the language inside
/// the scan, so no one needs a helper to change it.
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
                        .foregroundStyle(GridTheme.navy)
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
            .background(GridTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(GridTheme.navy.opacity(contrast == .increased ? 1 : 0.35), lineWidth: contrast == .increased ? 3 : 1.5)
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
            .font(GridTheme.rounded(.headline, .heavy))
            .lineLimit(1)
            .foregroundStyle(isCurrent ? Color.white : GridTheme.navy)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isCurrent ? GridTheme.navy : Color.clear, in: Capsule())
    }
}

/// The small navy "Next" tag a guided step puts on its next target.
struct GuideBadge: View {
    @Environment(Experience.self) private var experience

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
            Copy.guideNext.text(experience.language)
        }
        .font(GridTheme.rounded(.caption, .heavy))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(GridTheme.navy, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.white, lineWidth: 2)
        }
        .fixedSize()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Puts the "Next" tag on top of this view while `isOn`, and tells
    /// VoiceOver the same thing as a value ("Wife, Next").
    func guideMarker(_ isOn: Bool) -> some View {
        modifier(GuideMarkerModifier(isOn: isOn))
    }
}

private struct GuideMarkerModifier: ViewModifier {
    let isOn: Bool
    @Environment(Experience.self) private var experience

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isOn {
                    GuideBadge()
                        .offset(y: -12)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityValue(isOn ? Copy.guideNext.text(experience.language) : Text(verbatim: ""))
    }
}

/// How a scanned row looks: ringed when lit, outlined while its cells are
/// being scanned, and dimmed while another row is.
///
/// The ring is the same keyline-and-yellow as `scanHighlight`, drawn
/// without its small lift: a whole row is already big enough to find, and
/// lifting a full-width row would push its ring off the screen's edges.
struct ScanRowFrame: ViewModifier {
    let rowID: String
    let scanner: Scanner
    let isScanning: Bool

    @Environment(\.colorSchemeContrast) private var contrast

    @ViewBuilder
    func body(content: Content) -> some View {
        let lit = isScanning && scanner.isHighlighted(rowID)
        let entered = isScanning && scanner.isEntered(rowID)
        let dimmed = isScanning && !scanner.path.isEmpty && !entered
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        content
            .padding(BoardIDs.rowPadding)
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
        case .language: BoardIDs.language
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
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return HStack(spacing: 12) {
        TopicTab(topic: .pain, isSelected: true, isHighlighted: false) {}
        TopicTab(topic: .family, isSelected: false, isHighlighted: true) {}
            .guideMarker(true)
        LanguageCell(isHighlighted: false) {}
    }
    .frame(height: 68)
    .padding(30)
    .background(GridTheme.paper)
    .environment(experience)
    .holos(services)
}
