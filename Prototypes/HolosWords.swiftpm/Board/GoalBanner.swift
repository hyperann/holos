import SwiftUI

/// What a guided step asks for, shown above the board like a task written
/// at the top of a notebook page.
///
/// When the message is spoken, the goal is replaced by what the person
/// actually said. If nothing has moved for a while, "Show me" and "Skip
/// this step" appear here — first in the scan, so one press rescues anyone.
struct GoalBanner: View {
    let goal: WordsBoard.Goal
    var isScanning = false
    var compact = false

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var board: WordsBoard { experience.board }

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        // On a phone, once help is offered, Show me and Skip take the goal's
        // place. The goal has been in view for 45 s by then and the Next tag
        // still marks the route, while a banner grown by a row of buttons
        // would squeeze the words below under 44 points — just when someone
        // is struggling.
        let helpReplacesGoal = compact && board.helpOffered
        VStack(alignment: .leading, spacing: 8) {
            StepKicker(part: experience.step.part, title: title)
            if let said = experience.justSaid {
                Label {
                    Copy.youSaid(Bilingual.joined(said.map(\.speech))).text(language, gender)
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(HolosTheme.ink)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(WordKind.action.ink)
                        .accessibilityHidden(true)
                }
            } else if !helpReplacesGoal {
                goalText.text(language, gender)
                    .font(.system(compact ? .title3 : .title2, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                // On a phone the Next tag does this job, and the words for
                // the board need the room more than the instructions do.
                if !compact {
                    helpText.text(language, gender)
                        .font(.callout)
                        .foregroundStyle(WordsTheme.secondary(contrast))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // Drawn whenever the scan includes them, so the highlight never
            // lands on something invisible.
            if board.helpOffered {
                HStack(spacing: 12) {
                    BigButton(
                        title: Copy.showMe,
                        symbol: "hand.point.up.left.fill",
                        prominent: true,
                        isHighlighted: board.scanner.isHighlighted(ScanID.showMe),
                        hint: Copy.showMeHint
                    ) {
                        board.tap(ScanID.showMe)
                    }
                    BigButton(
                        title: Copy.skipStep,
                        symbol: "chevron.right",
                        isHighlighted: board.scanner.isHighlighted(ScanID.skip),
                        hint: Copy.skipStepHint
                    ) {
                        board.tap(ScanID.skip)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(experience.justSaid == nil ? WordKind.people.tint.opacity(0.45) : WordKind.action.tint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(HolosTheme.ink.opacity(contrast == .increased ? 0.8 : 0.15), lineWidth: 1)
        }
        .onAppear { announceGoal() }
        .onChange(of: goal) { announceGoal() }
    }

    private var title: Bilingual {
        switch goal {
        case .feelPainNeedMedicine: Copy.twoChoicesTitle
        case .callWife: Copy.findTitle
        }
    }

    private var goalText: Bilingual {
        switch goal {
        case .feelPainNeedMedicine: Copy.twoChoicesGoal
        case .callWife: Copy.findGoal
        }
    }

    private var helpText: Bilingual {
        switch goal {
        case .feelPainNeedMedicine: isScanning ? Copy.twoChoicesHelpScan : Copy.twoChoicesHelpTouch
        case .callWife: Copy.findHelp
        }
    }

    /// Every step change is announced, so a VoiceOver user knows the task.
    private func announceGoal() {
        let language = settings.language
        let words = Bilingual.joined([title, goalText], separator: ". ")
        announce(words(language, settings.gender), in: language)
    }
}

#Preview("Goal") {
    let experience = Experience()
    experience.show(.twoChoices)
    return GoalBanner(goal: .feelPainNeedMedicine, isScanning: true)
        .padding()
        .background(WordsTheme.paper)
        .environment(experience)
        .holos(.preview())
}
