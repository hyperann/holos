import SwiftUI

/// The whole board, under one line that keeps the conversation in view.
///
/// It takes the place of the chat and the answers while it is open: Holos
/// Grid's board needs the full width to keep its cells big. The line above
/// it still says what was asked, so nobody has to hold the question in mind
/// while building an answer — or, when nobody is asking, what the person
/// said last.
struct WholeBoardScreen: View {
    let isScanning: Bool
    /// True while presses go to this board: scanning, and nothing on top.
    let isSwitch: Bool

    @Environment(Experience.self) private var experience
    @Environment(Speaker.self) private var speaker

    var body: some View {
        let board = experience.board
        VStack(spacing: 10) {
            BoardStrip(isScanning: isScanning)
            GridBoardView(board: board, isScanning: isScanning, guide: experience.boardGuideTarget)
        }
        // A touch anywhere is the switch while scanning, as on the answers.
        .switchTapArea(isActive: isSwitch)
        // What the board said before it last closed never reached the
        // watcher below, which only runs while the board is on screen;
        // left standing, it would be taken for the board's own words the
        // next time the same message is spoken.
        .onAppear { board.speechEnded() }
        // Core's message bar speaks by itself when its Speak is tapped, so
        // the board learns of that message from the Speaker. Only while the
        // board is on screen: an answer cell's words are not the board's.
        .onChange(of: speaker.currentText) { _, text in
            if let text {
                board.speechStarted(text)
            } else {
                board.speechEnded()
            }
        }
    }
}

/// The line above the whole board: the question still waiting, with the
/// way back to its answers — or, when nobody is asking, what the person
/// said last.
private struct BoardStrip: View {
    let isScanning: Bool

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(Feedback.self) private var feedback
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let conversation = experience.conversation
        let compact = sizeClass == .compact
        HStack(spacing: compact ? 8 : 12) {
            Image(systemName: conversation.isAsking ? "bubble.left.fill" : "bubble.left.and.bubble.right.fill")
                .font(.system(size: compact ? 20 : 25, weight: .bold))
                .foregroundStyle(BedsideTheme.rust)
                .accessibilityHidden(true)
            line(compact: compact)
                .frame(maxWidth: .infinity, alignment: .leading)
            if conversation.isAsking {
                backButton(compact: compact)
            }
        }
        .padding(.leading, compact ? 10 : 16)
        .padding([.trailing, .vertical], compact ? 4 : 6)
        .frame(minHeight: compact ? 48 : 56)
        .background(BedsideTheme.peach.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BedsideTheme.line(contrast).opacity(contrast == .increased ? 1 : 0.5), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func line(compact: Bool) -> some View {
        let conversation = experience.conversation
        let language = settings.language
        let font = Font.bedside(compact ? .callout : .title3, weight: .bold)
        if conversation.isAsking {
            let prompt = conversation.prompt ?? conversation.question.prompt
            prompt.text(language)
                .font(font)
                .foregroundStyle(HolosTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Copy.questionLabel.text(language))
                .accessibilityValue(prompt.text(language))
        } else if let said = conversation.personLines.last {
            Self.youSaid(said.words, language, settings.gender)
                .font(font)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Copy.youSaid.text(language))
                .accessibilityValue(said.words.text(language, settings.gender))
        } else {
            Copy.boardHome.text(language)
                .font(font)
                .foregroundStyle(HolosTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }

    /// "You said:" and the person's words, in the quotation marks each
    /// language uses, as one string tagged with its language.
    private static func youSaid(_ words: Bilingual, _ language: Language, _ gender: SpeakerGender) -> Text {
        let said = words(language, gender)
        var label = AttributedString(Copy.youSaid(language) + ": ")
        label.foregroundColor = BedsideTheme.rust
        var quote = AttributedString(language == .ukrainian ? "«\(said)»" : "“\(said)”")
        quote.foregroundColor = HolosTheme.ink
        var line = label + quote
        line.languageIdentifier = language.localeIdentifier
        return Text(line)
    }

    /// "Back to the answers": the board's last scan stop, and a plain button
    /// to touch. The guide's tag sits on it when the turn's answer is with
    /// the answers rather than on the board.
    private func backButton(compact: Bool) -> some View {
        let language = settings.language
        let isGuide = experience.guideID == GridIDs.back
        let lit = isScanning && experience.board.scanner.isHighlighted(GridIDs.back)
        return Button {
            feedback.back()
            experience.closeBoard()
        } label: {
            Label {
                Copy.backToAnswers.text(language)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } icon: {
                Image(systemName: "arrow.uturn.backward")
            }
            .font(.bedside(compact ? .subheadline : .headline, weight: .bold))
            .foregroundStyle(WordKind.control.ink)
            .padding(.horizontal, compact ? 10 : 16)
            .frame(minHeight: 44)
            .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                if isGuide {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(BedsideTheme.terracotta, lineWidth: 4)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(lit, cornerRadius: 14)
        .boardGuide(isGuide)
        .accessibilityLabel(Copy.backToAnswers.text(language))
        .accessibilityHint(Copy.backToAnswersHint.text(language))
        .accessibilityInputLabels(Copy.backToAnswers.inputLabels)
    }
}

#Preview("Whole board — step 3") {
    let experience = Experience.preview(.conversation, boardOpen: true)
    return WholeBoardScreen(isScanning: true, isSwitch: false)
        .padding()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}

#Preview("Whole board — free, nobody asking") {
    let experience = Experience.preview(.free)
    return WholeBoardScreen(isScanning: false, isSwitch: false)
        .padding()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
