import SwiftUI

/// What to do right now in the guided story: the step, the goal, and one
/// line on how — plus "Show me" once someone has been stuck a while.
///
/// While the whole board is open, the second line follows the guide's tag
/// across it (the topic, the word, then Speak), so the banner drops its
/// "how" line: the guide line already says which press comes next.
struct GoalBanner: View {
    let isScanning: Bool
    /// True when either scan has lit "Show me".
    var showMeLit = false

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(Feedback.self) private var feedback
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let language = settings.language
        // A phone: every line of banner is a line the answer cells lose.
        let compact = sizeClass == .compact
        let headTry = experience.isShowingHeadTry
        if let turn = experience.currentTurn {
            VStack(alignment: .leading, spacing: 6) {
                turn.stepLabel.text(language)
                    .font(.bedside(.subheadline, weight: .heavy))
                    .foregroundStyle(BedsideTheme.rust)
                    .lineLimit(compact ? 1 : nil)
                    .minimumScaleFactor(compact ? 0.8 : 1)
                // While the head-turn panel is up, the turn's goal is done and
                // its board is under the panel, so the banner says only that
                // this part is optional.
                (headTry ? Copy.goalHeadTry : turn.goal).text(language)
                    .font(.bedside(.title2, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if !headTry {
                    if let detail = experience.guideDetail(compact: compact, scanning: isScanning) {
                        detail.text(language, settings.gender)
                            .font(.bedside(.body))
                            .foregroundStyle(BedsideTheme.softInk)
                            .lineLimit(compact ? 2 : 4)
                            .minimumScaleFactor(0.8)
                    }
                    let onBoard = experience.conversation.isBoardOpen
                    if !onBoard || experience.showMeOffered {
                        HStack(spacing: 12) {
                            if !onBoard {
                                Label {
                                    how.text(language)
                                } icon: {
                                    Image(systemName: "hand.point.up.left.fill")
                                }
                                .font(.bedside(.subheadline, weight: .semibold))
                                .foregroundStyle(BedsideTheme.rust)
                            }
                            if experience.showMeOffered {
                                showMeButton
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var how: Bilingual {
        isScanning ? Copy.howScan : Copy.howTouch
    }

    private var showMeButton: some View {
        Button {
            feedback.select()
            experience.showMe()
        } label: {
            Label {
                Copy.showMe.text(settings.language)
                    .font(.bedside(.headline, weight: .bold))
            } icon: {
                Image(systemName: "sparkles")
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(BedsideTheme.rust, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .scanHighlight(showMeLit, cornerRadius: 22)
        .accessibilityLabel(Copy.showMe.text(settings.language))
        .accessibilityHint(Copy.showMeHint.text(settings.language))
    }
}

/// The partner's question cards, for free conversation.
///
/// This row is for the carer, not the person: it is touch only and sits
/// outside the switch area. Tapping a card asks the question in the chat
/// and changes the whole board to the answers that fit it.
struct AskMenu: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(Feedback.self) private var feedback
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = settings.language
        VStack(alignment: .leading, spacing: 8) {
            Copy.askHeader.text(language)
                .font(.bedside(.subheadline, weight: .heavy))
                .foregroundStyle(BedsideTheme.rust)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(Question.allCases) { question in
                        questionCard(question, isCurrent: isWaiting(question))
                    }
                    actionChip(Copy.newConversation, hint: Copy.newConversationHint, symbol: "arrow.counterclockwise") {
                        feedback.back()
                        experience.newConversation()
                    }
                    actionChip(Copy.startAgain, hint: Copy.startAgainHint, symbol: "play.fill") {
                        feedback.enter()
                        experience.restart()
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Only a question still waiting for its answer is marked: once it is
    /// answered, the whole board is home and nobody is asking.
    private func isWaiting(_ question: Question) -> Bool {
        let conversation = experience.conversation
        return conversation.isAsking && conversation.question == question
    }

    private func questionCard(_ question: Question, isCurrent: Bool) -> some View {
        Button {
            feedback.enter()
            experience.partnerAsks(question)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: question.symbol)
                    .accessibilityHidden(true)
                question.prompt.text(settings.language)
                    .lineLimit(1)
            }
            .font(.bedside(.headline, weight: .bold))
            .foregroundStyle(isCurrent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(isCurrent ? BedsideTheme.personBubble(contrast) : BedsideTheme.card, in: Capsule())
            .overlay { Capsule().strokeBorder(BedsideTheme.line(contrast), lineWidth: 1.5) }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(question.prompt.text(settings.language))
        .accessibilityHint(Copy.askHint.text(settings.language))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func actionChip(_ title: Bilingual, hint: Bilingual, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .accessibilityHidden(true)
                title.text(settings.language)
                    .lineLimit(1)
            }
            .font(.bedside(.headline, weight: .bold))
            .foregroundStyle(WordKind.control.ink)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(WordKind.control.tint, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title.text(settings.language))
        .accessibilityHint(hint.text(settings.language))
    }
}

#Preview("Goal banner") {
    let experience = Experience.preview()
    return VStack(spacing: 30) {
        GoalBanner(isScanning: true)
        AskMenu()
    }
    .padding()
    .background(BedsideTheme.background)
    .environment(experience)
    .holos(experience.services)
}
