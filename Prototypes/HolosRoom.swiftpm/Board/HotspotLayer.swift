import SwiftUI

/// The objects you can press: an invisible button over each one, and a
/// small name pill on it.
///
/// The pills matter for aphasia: some people recognise the bed, others the
/// word "Bed", most a little of both — so the picture never stands alone.
/// The buttons are what touch and VoiceOver users reach; in scanning mode
/// the whole room is one switch and these are never hit directly.
struct HotspotLayer: View {
    let scale: CGFloat
    let isNarrow: Bool

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let place = experience.board.place
        let spotlight = experience.spotlight
        let showsPills = experience.stage != .problemAsk
        ZStack(alignment: .topLeading) {
            ForEach(place.hotspots) { spot in
                hotspotButton(spot, isLit: spotlight.hotspotID == spot.id)
            }
            if showsPills {
                ForEach(place.hotspots) { spot in
                    pill(spot, isLit: spotlight.hotspotID == spot.id, isDimmed: spotlight.dim > 0)
                }
            }
        }
    }

    private func hotspotButton(_ spot: Hotspot, isLit: Bool) -> some View {
        let rect = spot.frame.scaled(scale)
        let isOpen = experience.openHotspot?.id == spot.id
        let isGuide = experience.guideID == spot.id
        let language = settings.language
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return Button {
            experience.touchHotspot(spot.id)
        } label: {
            shape
                .fill(Color.white.opacity(0.001))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .frame(width: rect.width, height: rect.height)
        .overlay {
            // Opened: a quieter outline stays while its ring is showing.
            if isOpen {
                shape.strokeBorder(HolosTheme.highlight.opacity(0.9), lineWidth: 4)
            }
        }
        .scanHighlight(isLit && !isOpen, cornerRadius: 22)
        .disabled(experience.boardMode == .inert)
        // Behind a story card the objects cannot be used; VoiceOver keeps
        // the room's one-sentence description and the bubbles, and skips
        // these so the card is reached at once.
        .accessibilityHidden(experience.boardMode == .inert)
        .accessibilityLabel(spot.name.text(language))
        .accessibilityHint(Copy.hotspotHint.text(language))
        .accessibilityValue(isGuide ? Copy.nextStep.text(language) : Text(""))
        .accessibilityAddTraits(isOpen ? .isSelected : [])
        .accessibilityInputLabels(spot.name.inputLabels)
        .position(x: rect.midX, y: rect.midY)
    }

    private func pill(_ spot: Hotspot, isLit: Bool, isDimmed: Bool) -> some View {
        let point = spot.labelAt.scaled(scale)
        let isGuide = experience.guideID == spot.id
        let solid = contrast == .increased
        return spot.name.text(settings.language)
            .font(.system(isNarrow ? .caption : .subheadline, design: .rounded, weight: .bold))
            .lineLimit(1)
            .padding(.horizontal, isNarrow ? 7 : 11)
            .padding(.vertical, isNarrow ? 3 : 5)
            .foregroundStyle(isLit ? HolosTheme.ink : Color.white)
            .background(isLit ? HolosTheme.highlight : Color.black.opacity(solid ? 0.92 : 0.6), in: Capsule())
            .overlay {
                Capsule().strokeBorder(
                    isLit ? HolosTheme.keyline : Color.white.opacity(solid ? 0.9 : 0.35),
                    lineWidth: isLit ? 2 : 1
                )
            }
            .fixedSize()
            .opacity(isDimmed && !isLit ? 0.6 : 1)
            .overlay(alignment: .top) {
                if isGuide {
                    GuideMarker().offset(y: -40)
                }
            }
            // The pills label a picture; at the largest text sizes they would
            // cover it. VoiceOver and the ring cells carry the large text.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .position(point)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Hotspots") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return ZStack(alignment: .topLeading) {
        WardArt().scaleEffect(0.7, anchor: .topLeading)
        HotspotLayer(scale: 0.7, isNarrow: false)
    }
    .frame(width: 700, height: 490, alignment: .topLeading)
    .holos(services)
    .environment(experience)
}
