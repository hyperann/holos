import SwiftUI

/// The frame for the tour's reading screens: text above, choices below.
///
/// In scanning mode the whole page is the switch. When the text fits —
/// the usual case on an iPad — the page uses Core's touch-down switch
/// area. When large text makes it overflow, the page scrolls instead, and
/// a tap on the text still counts as a press: the touch-down area would
/// swallow the scroll gesture, and content that cannot be reached is worse
/// than a press that lands on lift. The choices are pinned below the text
/// so they are always on screen.
struct NarrativePage<Content: View, Actions: View>: View {
    let isScanning: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let actions: () -> Actions

    @Environment(SwitchHub.self) private var hub

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
                .padding(.horizontal, 20)
                .padding(.top, 12)
            ViewThatFits(in: .vertical) {
                page
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .switchTapArea(isActive: isScanning)
                ScrollView {
                    page
                        .contentShape(Rectangle())
                        .gesture(TapGesture().onEnded { hub.press(.tap) }, including: isScanning ? .all : .subviews)
                }
            }
            VStack(spacing: 12) {
                actions()
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .switchTapArea(isActive: isScanning)
        }
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 20) {
            content()
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

/// The small line above a step's title: "Step 2 of 4 · The problem".
struct StepKicker: View {
    let part: Int?
    let title: Bilingual

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let words = part.map { Bilingual.joined([Copy.stepOf($0), title], separator: " · ") } ?? title
        words.text(settings.language)
            .font(.system(.subheadline, design: .rounded, weight: .heavy))
            .textCase(.uppercase)
            .foregroundStyle(WordsTheme.secondary(contrast))
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Narrative page") {
    NarrativePage(isScanning: true) {
        StepKicker(part: 1, title: Copy.problemKicker)
        Copy.problemTitle.text(.english)
            .font(.system(.largeTitle, design: .serif, weight: .bold))
        Copy.problemBody.text(.english)
            .font(.title3)
    } actions: {
        BigButton(title: Copy.begin, symbol: "chevron.right", prominent: true) {}
    }
    .environment(Experience())
    .holos(.preview())
}
