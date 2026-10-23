import SwiftUI

/// One of the four big choices around the centre.
///
/// Picture and word, always both, in the Fitzgerald colour therapists
/// already use on paper boards. Each petal also carries a small arrow for
/// its direction, so "up means Yes" is learnt by the eye before a head
/// ever tries to point — and that arrow is where the hold ring fills.
struct PetalView: View {
    let choice: CompassChoice
    let direction: Direction
    var isLit = false
    var isGuide = false
    /// 0…1 while a head is holding on this petal.
    var pointProgress: Double = 0
    /// A brief glow just after this petal was chosen.
    var isFlashing = false
    /// Too narrow for both the "Next" tag and the direction arrow along the
    /// top edge (the side petals on a phone).
    var isNarrow = false
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        Button(action: action) {
            GeometryReader { geometry in
                let size = geometry.size
                let wide = size.width > size.height * 1.3
                Group {
                    if wide {
                        HStack(spacing: 16) {
                            symbol(side: min(size.height * 0.58, 110))
                            label(size: max(min(size.height * 0.3, 54), 20), alignment: .leading)
                        }
                    } else {
                        VStack(spacing: 10) {
                            symbol(side: min(size.width * 0.5, size.height * 0.4, 110))
                            label(size: max(min(size.width * 0.17, 48), 20), alignment: .center)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(width: size.width, height: size.height)
            }
            .background(choice.kind.tint, in: shape)
            .overlay {
                shape.strokeBorder(
                    choice.kind.ink.opacity(contrast == .increased ? 1 : 0.45),
                    lineWidth: contrast == .increased ? 3 : 2
                )
            }
            .overlay(alignment: .topTrailing) {
                // On a narrow petal the tag and the arrow would sit on top of
                // each other, and the tag matters more while it is shown. The
                // arrow comes back whenever a head holds here: it carries
                // the hold ring.
                if !(isGuide && isNarrow) || pointProgress > 0 {
                    directionBadge
                        .padding(10)
                }
            }
            .overlay(alignment: .topLeading) {
                if isGuide {
                    GuideMarker()
                        .padding(10)
                }
            }
            .overlay {
                // An opacity glow, not movement: fine under Reduce Motion.
                shape
                    .fill(Color.white.opacity(isFlashing ? 0.55 : 0))
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.3), value: isFlashing)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .scanHighlight(isLit, cornerRadius: 28)
        .accessibilityLabel(choice.label.text(language, gender))
        .accessibilityValue(valueText(language))
        .accessibilityHint((choice.opensLevel ? Copy.Board.opensHint : CoreCopy.cellHintSpeak).text(language))
        .accessibilityAddTraits(isLit ? .isSelected : [])
        .accessibilityInputLabels(choice.label.inputLabels)
    }

    private func symbol(side: CGFloat) -> some View {
        Image(systemName: choice.symbol)
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(choice.kind.ink)
            .frame(width: max(side, 24), height: max(side, 24))
            .accessibilityHidden(true)
    }

    private func label(size: CGFloat, alignment: TextAlignment) -> some View {
        choice.label.text(settings.language, settings.gender)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(HolosTheme.ink)
            .multilineTextAlignment(alignment)
            .lineLimit(2)
            .minimumScaleFactor(0.4)
    }

    /// The direction arrow, wrapped in the hold ring while a head points.
    private var directionBadge: some View {
        ZStack {
            Circle()
                .fill(HolosTheme.paper.opacity(0.75))
            if pointProgress > 0 {
                // Black under yellow, like every highlight in Holos: yellow
                // alone nearly vanishes on the paler petals.
                Circle()
                    .trim(from: 0, to: pointProgress)
                    .stroke(HolosTheme.keyline, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: 0, to: pointProgress)
                    .stroke(HolosTheme.highlight, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Image(systemName: direction.arrowSymbol)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(choice.kind.ink)
        }
        .frame(width: pointProgress > 0 ? 56 : 40, height: pointProgress > 0 ? 56 : 40)
        .accessibilityHidden(true)
    }

    private func valueText(_ language: Language) -> Text {
        let place = Copy.Board.directionName(direction).text(language)
        guard isGuide else { return place }
        return place + Text(verbatim: ". ") + Copy.Board.suggested.text(language)
    }
}

#Preview("Petals") {
    let need = Vocabulary.home.south
    let yes = Vocabulary.home.north
    HStack(spacing: 16) {
        PetalView(choice: yes, direction: .north, isLit: true, pointProgress: 0.6) {}
            .frame(width: 320, height: 150)
        PetalView(choice: need, direction: .south, isGuide: true) {}
            .frame(width: 180, height: 260)
    }
    .padding(30)
    .background(CompassTheme.background)
    .holos(.preview())
}
