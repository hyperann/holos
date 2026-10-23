import SwiftUI

/// The one closing screen: who Holos is for, and why it is free, private
/// and open source. Then the choice — keep talking on the real board, or
/// start the tour again — scanned like every other choice in the app.
///
/// When scanning, the choice does not start lighting up until a first press
/// says "I have read this": a press made after reading then always lands on
/// "Keep talking", never on whichever choice the scan happened to reach.
struct ClosingStep: View {
    @Environment(Experience.self) private var experience

    var body: some View {
        let language = experience.language
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Copy.closingTitle.text(language)
                        .font(GridTheme.rounded(.largeTitle))
                        .foregroundStyle(GridTheme.navy)
                        .accessibilityAddTraits(.isHeader)
                    Copy.closingBody.text(language)
                        .font(.title3)
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Copy.closingSource.text(language)
                        .font(.footnote)
                        .foregroundStyle(GridTheme.quietInk)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 14) { pillars }
                        VStack(alignment: .leading, spacing: 12) { pillars }
                    }
                }
                .frame(maxWidth: 820, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Scanning: a tap on the text is the switch, but a drag still
            // scrolls it — on a phone the three pillars sit below the fold.
            .narrativeTapArea(isActive: experience.modeIsScanning)

            VStack(spacing: 10) {
                if experience.modeIsScanning {
                    choosingStatus(language)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { choiceButtons }
                    VStack(spacing: 12) { choiceButtons }
                }
            }
            .frame(maxWidth: 820)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            // Nothing here scrolls, so Core's touch-down area can cover it:
            // scanning, a touch is the switch and the two choices are
            // scanned. Touch: the two buttons are simply tapped.
            .switchTapArea(isActive: experience.modeIsScanning)
        }
    }

    /// What a press does next: start choosing, or wake a scan that stopped
    /// to rest. While the choices are lighting up the line keeps its place,
    /// so the buttons never jump under the ring.
    private func choosingStatus(_ language: Language) -> some View {
        let state = experience.choices.state
        return (state == .paused ? Copy.scanPaused : Copy.pressToChoose).text(language)
            .font(GridTheme.rounded(.headline))
            .foregroundStyle(GridTheme.navy)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .opacity(state == .scanning ? 0 : 1)
            .accessibilityHidden(state == .scanning)
    }

    @ViewBuilder
    private var pillars: some View {
        Pillar(symbol: "gift.fill", title: Copy.pillarFree, detail: Copy.pillarFreeDetail)
        Pillar(symbol: "lock.fill", title: Copy.pillarPrivate, detail: Copy.pillarPrivateDetail)
        Pillar(symbol: "person.3.fill", title: Copy.pillarOpen, detail: Copy.pillarOpenDetail)
    }

    @ViewBuilder
    private var choiceButtons: some View {
        ChoiceButton(
            id: Experience.keepTalkingID,
            symbol: "bubble.left.and.bubble.right.fill",
            title: Copy.keepTalking,
            hint: Copy.keepTalkingHint,
            prominent: true
        ) {
            experience.keepTalking()
        }
        ChoiceButton(
            id: Experience.startAgainID,
            symbol: "arrow.counterclockwise",
            title: Copy.startAgain,
            hint: Copy.startAgainHint,
            prominent: false
        ) {
            experience.restart()
        }
    }
}

private struct Pillar: View {
    let symbol: String
    let title: Bilingual
    let detail: Bilingual

    @Environment(Experience.self) private var experience

    var body: some View {
        let language = experience.language
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(GridTheme.navy)
                .accessibilityHidden(true)
            title.text(language)
                .font(GridTheme.rounded(.title3))
                .foregroundStyle(GridTheme.navy)
            detail.text(language)
                .font(.body)
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gridCard(padding: 18)
        .accessibilityElement(children: .combine)
    }
}

private struct ChoiceButton: View {
    let id: String
    let symbol: String
    let title: Bilingual
    let hint: Bilingual
    let prominent: Bool
    let action: () -> Void

    @Environment(Experience.self) private var experience
    @Environment(Feedback.self) private var feedback
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = experience.language
        Button {
            feedback.select()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .accessibilityHidden(true)
                title.text(language)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .font(GridTheme.rounded(.title2))
            .foregroundStyle(prominent ? Color.white : GridTheme.navy)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(prominent ? GridTheme.navy : GridTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(GridTheme.navy, lineWidth: prominent ? 0 : (contrast == .increased ? 3 : 2))
            }
        }
        .buttonStyle(.plain)
        .scanHighlight(experience.choices.isHighlighted(id), cornerRadius: 20)
        .accessibilityLabel(title.text(language))
        .accessibilityHint(hint.text(language))
        .accessibilityInputLabels(title.inputLabels)
    }
}

#Preview("Closing") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.closing)
    return ClosingStep()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
