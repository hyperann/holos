import SwiftUI

/// The goal, always in view while a guided step is being worked on.
///
/// It answers the three questions a stuck person has, in order: what am I
/// trying to say, where do I go next, and is there a way out. The way out
/// ("Show me") appears only after a long pause, and is scanned first.
struct GoalCard: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub

    private var title: Bilingual {
        experience.step == .aphasia ? Copy.aphasiaTitle : Copy.oneSwitchTitle
    }

    private var reminder: Bilingual {
        if experience.step == .aphasia { return Copy.aphasiaReminder }
        return experience.modeIsScanning ? Copy.reminderScanning : Copy.reminderTouch
    }

    var body: some View {
        let language = experience.language
        let gender = settings.gender
        let board = experience.board
        // Three short lines, so the board below keeps its height on an iPad
        // in landscape: what this is, what to say, where to go next.
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                title.text(language)
                    .font(GridTheme.rounded(.title3))
                    .foregroundStyle(GridTheme.navy)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if experience.modeIsScanning, experience.phase == .working {
                    Copy.presses(max(0, hub.pressCount - experience.pressBaseline)).text(language)
                        .font(GridTheme.rounded(.headline))
                        .monospacedDigit()
                        .foregroundStyle(GridTheme.navy)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(GridTheme.paper, in: Capsule())
                }
            }
            if let guide = board.guide {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Copy.goalSay.text(language)
                        .font(.headline)
                        .foregroundStyle(GridTheme.quietInk)
                    Copy.quoted(guide.sentence).text(language, gender)
                        .font(GridTheme.rounded(.title3))
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    nextLine(language, gender)
                    statusLine(language)
                }
                VStack(alignment: .leading, spacing: 4) {
                    nextLine(language, gender)
                    statusLine(language)
                }
            }
            if board.offersShowMe {
                ShowMeRow()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gridCard(padding: 14)
    }

    @ViewBuilder
    private func nextLine(_ language: Language, _ gender: SpeakerGender) -> some View {
        if experience.phase == .working, let target = experience.board.guideTarget {
            Label {
                Copy.nextHint(target).text(language, gender)
            } icon: {
                Image(systemName: "arrow.down")
                    .accessibilityHidden(true)
            }
            .font(GridTheme.rounded(.headline))
            .foregroundStyle(GridTheme.navy)
        }
    }

    /// The reminder of how to choose — or, if the scan has stopped to rest,
    /// how to wake it, which matters more.
    @ViewBuilder
    private func statusLine(_ language: Language) -> some View {
        if experience.board.scanner.state == .paused {
            Copy.scanPaused.text(language)
                .font(.subheadline.bold())
                .foregroundStyle(GridTheme.navy)
        } else {
            reminder.text(language)
                .font(.subheadline)
                .foregroundStyle(GridTheme.quietInk)
        }
    }
}

/// The way out of a stalled step: Holos builds the message and says it.
private struct ShowMeRow: View {
    @Environment(Experience.self) private var experience

    var body: some View {
        let language = experience.language
        let board = experience.board
        HStack(spacing: 12) {
            Copy.stuckNote.text(language)
                .font(.subheadline)
                .foregroundStyle(HolosTheme.ink)
            Spacer(minLength: 8)
            Button {
                board.tapShowMe()
            } label: {
                Label {
                    Copy.showMe.text(language)
                } icon: {
                    Image(systemName: "play.fill")
                        .accessibilityHidden(true)
                }
                .font(GridTheme.rounded(.headline))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .frame(minHeight: 48)
                .background(GridTheme.navy, in: Capsule())
            }
            .buttonStyle(.plain)
            .scanHighlight(board.scanner.isHighlighted(BoardIDs.showMe), cornerRadius: 24)
            .accessibilityLabel(Copy.showMe.text(language))
            .accessibilityHint(Copy.showMeHint.text(language))
            .accessibilityInputLabels(Copy.showMe.inputLabels)
        }
        .padding(10)
        .background(WordKind.people.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("Goal card") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.oneSwitch)
    return GoalCard()
        .padding()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
