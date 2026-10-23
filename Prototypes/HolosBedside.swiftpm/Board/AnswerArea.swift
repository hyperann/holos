import SwiftUI

/// Everything the person can answer with: the question card, the predicted
/// answers, and the Yes · No · Not sure · Something else strip — or, after
/// "Something else", the small topic board.
struct AnswerArea: View {
    let scanner: Scanner
    let isScanning: Bool

    @Environment(Experience.self) private var experience
    @Environment(Feedback.self) private var feedback
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let conversation = experience.conversation
        GeometryReader { geometry in
            let roomy = geometry.size.width > 560
            // Short on height — a phone in portrait. The extras give way so
            // every answer keeps a target a shaking hand can hit.
            let tight = geometry.size.height < 420
            VStack(spacing: tight ? 10 : 14) {
                QuestionHeader(
                    prompt: conversation.prompt ?? conversation.question.prompt,
                    maxLines: tight ? 1 : 2
                )
                if conversation.isMiniBoardOpen {
                    MiniBoardView(scanner: scanner, isScanning: isScanning, compact: tight, onTap: tap)
                } else {
                    mainAnswers(conversation.question, roomy: roomy, tight: tight)
                    StripRow(
                        phrases: conversation.question.strip,
                        scanner: scanner,
                        guideID: experience.guideID,
                        horizontal: roomy,
                        onTap: tap
                    )
                    .frame(height: roomy ? 84 : (tight ? 72 : 96))
                }
            }
        }
        .opacity(conversation.isPartnerTurn ? 0.45 : 1)
        .overlay {
            if conversation.isPartnerTurn, experience.step == .conversation {
                Copy.nurseAnswering.text(settings.language)
                    .font(.bedside(.title3, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(BedsideTheme.card, in: Capsule())
                    .shadow(color: BedsideTheme.shadow, radius: 8, y: 4)
                    .accessibilityHidden(true)
            }
        }
        .disabled(conversation.isPartnerTurn)
        .animation(.easeInOut(duration: 0.25), value: conversation.isPartnerTurn)
    }

    @ViewBuilder
    private func mainAnswers(_ question: Question, roomy: Bool, tight: Bool) -> some View {
        let answers = question.answers
        let guide = experience.guideID
        switch question.layout {
        case .cells:
            AnswerGrid(phrases: answers, scanner: scanner, guideID: guide, onTap: tap)
        case .scale:
            AnswerGrid(phrases: answers, scanner: scanner, guideID: guide, isScale: true, onTap: tap)
        case .bodyMap:
            HStack(spacing: 14) {
                BodyMapFigure(
                    highlighted: scanner.highlightedID.flatMap(BodyRegion.init(phraseID:)),
                    guide: guide.flatMap(BodyRegion.init(phraseID:)),
                    tapEnabled: !isScanning,
                    onTap: { region in tap(region.phraseID) }
                )
                .frame(maxWidth: roomy ? 200 : (tight ? 110 : 130))
                AnswerGrid(phrases: answers, scanner: scanner, guideID: guide, columns: 2, onTap: tap)
            }
        }
    }

    /// A touch on a cell. Scanning gets its select feel from Core; touch
    /// gets the same feel here, so both routes feel identical.
    private func tap(_ id: String) {
        feedback.select()
        experience.activate(id)
    }
}

/// The question being answered, kept in view above the answers so nobody
/// has to hold it in mind while choosing: short-term memory is often hit
/// by a stroke or a brain injury along with language.
struct QuestionHeader: View {
    let prompt: Bilingual
    /// One line on a short screen; it shrinks to fit rather than wrap.
    var maxLines = 2

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(BedsideTheme.rust)
                .accessibilityHidden(true)
            prompt.text(settings.language)
                .font(.bedside(.title2, weight: .bold))
                .foregroundStyle(HolosTheme.ink)
                .lineLimit(maxLines)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(BedsideTheme.peach.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BedsideTheme.line(contrast).opacity(contrast == .increased ? 1 : 0.5), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.questionLabel.text(settings.language))
        .accessibilityValue(prompt.text(settings.language))
    }
}

/// Up to six big cells, laid out to fill the space.
///
/// Wide spaces get one or two rows of three (or one row of four for a
/// scale, so it reads left to right like a ruler); narrow ones get two
/// columns, or one column for a scale so its order still reads top to
/// bottom.
struct AnswerGrid: View {
    let phrases: [Phrase]
    let scanner: Scanner
    var guideID: String?
    var isScale = false
    var columns: Int?
    let onTap: (String) -> Void

    private static let spacing: CGFloat = 14

    var body: some View {
        GeometryReader { geometry in
            let perRow = columnCount(for: geometry.size)
            let rowCount = max(1, (phrases.count + perRow - 1) / perRow)
            let spacing = Self.spacing
            let cellWidth = max(0, (geometry.size.width - spacing * CGFloat(perRow - 1)) / CGFloat(perRow))
            let cellHeight = max(0, (geometry.size.height - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount))
            let horizontal = cellWidth > cellHeight * 1.7
            VStack(spacing: spacing) {
                ForEach(0..<rowCount, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<perRow, id: \.self) { column in
                            let index = row * perRow + column
                            if phrases.indices.contains(index) {
                                cell(phrases[index], index: index, horizontal: horizontal)
                                    .frame(width: cellWidth, height: cellHeight)
                            } else {
                                Color.clear
                                    .frame(width: cellWidth, height: cellHeight)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cell(_ phrase: Phrase, index: Int, horizontal: Bool) -> some View {
        AnswerCell(
            phrase: phrase,
            isHighlighted: scanner.isHighlighted(phrase.id),
            isGuide: guideID == phrase.id,
            horizontal: horizontal,
            faceLevel: isScale ? index : nil,
            hint: phrase.id == Vocabulary.somethingElse.id ? Copy.somethingElseHint : CoreCopy.cellHintSpeak
        ) {
            onTap(phrase.id)
        }
    }

    private func columnCount(for size: CGSize) -> Int {
        if let columns { return max(1, columns) }
        let count = max(1, phrases.count)
        let wide = size.width > size.height * 1.3
        if isScale { return wide ? count : 1 }
        if wide { return count <= 4 ? count : 3 }
        return count <= 2 ? count : 2
    }
}

/// Yes · No · Not sure · Something else: under every question, because a
/// prediction should help, never trap.
struct StripRow: View {
    let phrases: [Phrase]
    let scanner: Scanner
    var guideID: String?
    var horizontal = true
    let onTap: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(phrases) { phrase in
                AnswerCell(
                    phrase: phrase,
                    isHighlighted: scanner.isHighlighted(phrase.id),
                    isGuide: guideID == phrase.id,
                    horizontal: horizontal,
                    compact: true,
                    hint: phrase.id == Vocabulary.somethingElse.id ? Copy.somethingElseHint : CoreCopy.cellHintSpeak
                ) {
                    onTap(phrase.id)
                }
            }
        }
    }
}

#Preview("Answer area") {
    let experience = Experience.preview()
    return AnswerArea(scanner: Scanner(), isScanning: false)
        .padding()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
