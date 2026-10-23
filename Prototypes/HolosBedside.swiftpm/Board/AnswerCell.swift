import SwiftUI

/// One big answer: a picture and a word, sized for a hand that shakes or
/// eyes that tire.
///
/// The picture sits on a disc in its Fitzgerald colour, so the colour
/// coding therapists already use on paper boards still carries over, while
/// the card itself stays in the warm Bedside palette.
struct AnswerCell: View {
    let phrase: Phrase
    var isHighlighted = false
    /// The guide marker: "this one" during the story.
    var isGuide = false
    /// Picture beside the word instead of above it, for wide, short cells.
    var horizontal = false
    /// Smaller type for the Yes / No strip.
    var compact = false
    /// Draws a pain-scale face (0…3) instead of the symbol.
    var faceLevel: Int?
    var hint: Bilingual = CoreCopy.cellHintSpeak
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let label = phrase.label(settings.language, settings.gender)
        Button(action: action) {
            content(label)
                .padding(compact ? 10 : 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BedsideTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(border, lineWidth: borderWidth)
                }
                .shadow(color: BedsideTheme.shadow, radius: 8, y: 4)
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if isGuide {
                GuideMarker(compact: compact)
                    .padding(compact ? 4 : 8)
            }
        }
        .scanHighlight(isHighlighted, cornerRadius: 24)
        .accessibilityLabel(Text(phrase.label.spoken(settings.language, settings.gender)))
        .accessibilityHint(hint.text(settings.language))
        .accessibilityValue(isGuide ? Copy.suggested.text(settings.language) : Text(""))
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
        .accessibilityInputLabels(phrase.label.inputLabels)
    }

    /// The guide gets a terracotta outline as well as its tag, so it can
    /// be found by shape and colour, not by reading.
    private var border: Color {
        if isGuide { return BedsideTheme.terracotta }
        return BedsideTheme.line(contrast).opacity(contrast == .increased ? 1 : 0.6)
    }

    private var borderWidth: CGFloat {
        if isGuide { return 4 }
        return contrast == .increased ? 2.5 : 1.5
    }

    @ViewBuilder
    private func content(_ label: String) -> some View {
        if horizontal {
            HStack(spacing: 14) {
                art
                    .frame(maxHeight: .infinity)
                    .frame(maxWidth: compact ? 52 : 110)
                word(label)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 10) {
                art
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                word(label)
            }
        }
    }

    private func word(_ label: String) -> some View {
        Text(label)
            .font(.bedside(compact ? .title3 : .largeTitle, weight: .bold))
            .foregroundStyle(HolosTheme.ink)
            .multilineTextAlignment(horizontal ? .leading : .center)
            .lineLimit(2)
            .minimumScaleFactor(0.45)
    }

    private var art: some View {
        Group {
            if let faceLevel {
                PainFace(level: faceLevel)
            } else {
                Circle()
                    .fill(phrase.kind.tint)
                    .overlay {
                        Image(systemName: phrase.symbol)
                            .resizable()
                            .scaledToFit()
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(phrase.kind.ink)
                            .scaleEffect(0.56)
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// The small tag that marks the next answer in the guided story. It says
/// "this one", it never says "wrong".
struct GuideMarker: View {
    var compact = false

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.point.up.left.fill")
            if !compact {
                Copy.guideMarker.text(settings.language)
                    .lineLimit(1)
            }
        }
        .font(.bedside(.subheadline, weight: .heavy))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(BedsideTheme.rust, in: Capsule())
        .overlay { Capsule().strokeBorder(Color.white, lineWidth: 2) }
        .fixedSize()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A face for the pain scale, drawn from circles and one curve.
///
/// Faces carry the scale for someone who cannot read "Medium": the mouth
/// turns from a smile to a frown as the pain grows.
struct PainFace: View {
    /// 0 = a little … 3 = the worst ever.
    let level: Int

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(fill)
                Circle()
                    .strokeBorder(HolosTheme.ink, lineWidth: max(size * 0.04, 1.5))
                HStack(spacing: size * 0.2) {
                    eye(size: size)
                    eye(size: size)
                }
                .offset(y: -size * 0.1)
                MouthShape(curve: curve)
                    .stroke(HolosTheme.ink, style: StrokeStyle(lineWidth: max(size * 0.06, 2), lineCap: .round))
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func eye(size: CGFloat) -> some View {
        Capsule()
            .fill(HolosTheme.ink)
            // Squeezed shut at the top of the scale.
            .frame(width: size * 0.09, height: level >= 3 ? size * 0.04 : size * 0.12)
    }

    private var curve: CGFloat {
        switch level {
        case ...0: 0.9
        case 1: 0.15
        case 2: -0.55
        default: -1
        }
    }

    private var fill: Color {
        switch level {
        case ...0: WordKind.action.tint
        case 1: WordKind.people.tint
        case 2: WordKind.thing.tint
        default: WordKind.urgent.tint
        }
    }
}

/// The mouth: a smile when `curve` is positive, a frown when negative.
struct MouthShape: Shape {
    var curve: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.minY + rect.height * 0.68
        let left = CGPoint(x: rect.minX + rect.width * 0.3, y: y)
        let right = CGPoint(x: rect.minX + rect.width * 0.7, y: y)
        let control = CGPoint(x: rect.midX, y: y + rect.height * 0.2 * curve)
        path.move(to: left)
        path.addQuadCurve(to: right, control: control)
        return path
    }
}

#Preview("Answer cells") {
    let experience = Experience.preview()
    return HStack(spacing: 16) {
        if let pain = Vocabulary.phrase(id: "feel.pain") {
            AnswerCell(phrase: pain, isHighlighted: true, isGuide: true) {}
        }
        if let lot = Vocabulary.phrase(id: "scale.lot") {
            AnswerCell(phrase: lot, faceLevel: 2) {}
        }
        if let yes = Vocabulary.phrase(id: "yes") {
            AnswerCell(phrase: yes, horizontal: true, compact: true) {}
                .frame(height: 84)
        }
    }
    .frame(height: 260)
    .padding()
    .background(BedsideTheme.background)
    .environment(experience)
    .holos(experience.services)
}
