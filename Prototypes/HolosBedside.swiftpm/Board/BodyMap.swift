import SwiftUI

/// A simple front-facing body, drawn from rounded shapes, for "Where does
/// it hurt?".
///
/// Pointing is older than words: a person who cannot say "stomach" can
/// still recognise where their own stomach is. The scan lights the region
/// on the figure and its labelled cell at the same moment, so the picture
/// and the word confirm each other.
struct BodyMapFigure: View {
    /// The region the scan has lit.
    var highlighted: BodyRegion?
    /// The region the guide marker points to.
    var guide: BodyRegion?
    /// Touch mode only: the figure itself can be tapped.
    var tapEnabled = false
    let onTap: (BodyRegion) -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    /// Height is this many times the width: a standing figure.
    private static let aspect: CGFloat = 1.8

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height / Self.aspect)
            let size = CGSize(width: width, height: width * Self.aspect)
            ZStack {
                // The back peeks out around the torso, so "my back" has a
                // place to light up on a figure seen from the front.
                part(.back, CGRect(x: 0.23, y: 0.15, width: 0.54, height: 0.36), in: size, dashed: true)
                part(.head, CGRect(x: 0.37, y: 0.0, width: 0.26, height: 0.14), in: size)
                part(.chest, CGRect(x: 0.28, y: 0.165, width: 0.44, height: 0.16), in: size)
                part(.stomach, CGRect(x: 0.28, y: 0.335, width: 0.44, height: 0.16), in: size)
                part(.arm, CGRect(x: 0.07, y: 0.17, width: 0.13, height: 0.34), in: size)
                part(.arm, CGRect(x: 0.80, y: 0.17, width: 0.13, height: 0.34), in: size)
                part(.leg, CGRect(x: 0.29, y: 0.52, width: 0.19, height: 0.47), in: size)
                part(.leg, CGRect(x: 0.52, y: 0.52, width: 0.19, height: 0.47), in: size)
            }
            .frame(width: size.width, height: size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        // The labelled cells beside the figure carry every region for
        // VoiceOver; the drawing itself would only repeat them.
        .accessibilityHidden(true)
    }

    private func part(_ region: BodyRegion, _ unit: CGRect, in size: CGSize, dashed: Bool = false) -> some View {
        let rect = CGRect(
            x: unit.minX * size.width,
            y: unit.minY * size.height,
            width: unit.width * size.width,
            height: unit.height * size.height
        )
        let isLit = highlighted == region
        let isGuide = guide == region && !isLit
        let radius = min(rect.width, rect.height) * (region == .head ? 0.5 : 0.38)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return shape
            .fill(isLit ? HolosTheme.highlight : fill(for: region))
            .overlay {
                shape.strokeBorder(
                    strokeColor(isLit: isLit, isGuide: isGuide),
                    style: StrokeStyle(lineWidth: isLit ? 5 : (isGuide ? 4 : 2), dash: dashed && !isLit ? [6, 4] : [])
                )
            }
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .onTapGesture {
                if tapEnabled { onTap(region) }
            }
            .allowsHitTesting(tapEnabled)
    }

    private func fill(for region: BodyRegion) -> Color {
        region == .back ? BedsideTheme.chatBackground : BedsideTheme.peach
    }

    private func strokeColor(isLit: Bool, isGuide: Bool) -> Color {
        if isLit { return HolosTheme.keyline }
        if isGuide { return BedsideTheme.terracotta }
        return contrast == .increased ? HolosTheme.ink : BedsideTheme.rust.opacity(0.55)
    }
}

#Preview("Body map") {
    BodyMapFigure(highlighted: .head, guide: .chest) { _ in }
        .frame(width: 220, height: 420)
        .padding()
        .background(BedsideTheme.background)
}
