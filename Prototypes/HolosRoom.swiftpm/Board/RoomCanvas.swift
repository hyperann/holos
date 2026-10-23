import SwiftUI

/// The room as a board: the picture, the spotlight, the objects, the
/// speech bubbles, and — on wide screens — the ring of phrases.
///
/// Everything is laid out in room space and scaled to fit, so the same
/// room works on a 13-inch iPad in landscape and an iPhone in portrait.
/// Only the picture is scaled as an image; pills, bubbles and cells are
/// laid out in real points, so their text stays sharp and honours Dynamic
/// Type.
struct RoomCanvas: View {
    let isNarrow: Bool

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let scale = size.width / RoomSpace.width
            ZStack(alignment: .topLeading) {
                art(scale: scale, size: size)
                veil(scale: scale, size: size)
                HotspotLayer(scale: scale, isNarrow: isNarrow)
                bubbles(scale: scale, size: size)
                if !isNarrow {
                    RingLayer(size: size, scale: scale)
                }
                if experience.isPaused {
                    pausedBadge
                        .position(x: size.width / 2, y: max(size.height - 36, 24))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .animation(.easeInOut(duration: reduceMotion ? 0.25 : 0.38), value: experience.spotlight)
            .animation(.easeInOut(duration: 0.45), value: experience.board.place)
            .animation(
                reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.34, dampingFraction: 0.82),
                value: experience.ringItems.map(\.id)
            )
            .animation(.easeOut(duration: 0.25), value: experience.board.spoken)
        }
        .aspectRatio(RoomSpace.aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(RoomTheme.outline(contrast), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Layers

    /// The picture, drawn once in room space and scaled as a single image.
    /// To VoiceOver it is one element: a sentence describing the room.
    private func art(scale: CGFloat, size: CGSize) -> some View {
        let place = experience.board.place
        return Group {
            switch place {
            case .ward: WardArt()
            case .home: HomeArt()
            }
        }
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .drawingGroup()
        .id(place)
        .transition(.opacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(place.sceneDescription.text(settings.language))
        .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private func veil(scale: CGFloat, size: CGSize) -> some View {
        let spotlight = experience.spotlight
        // Increase Contrast darkens the rest of the room further, so the lit
        // object stands out more.
        let dim = min(spotlight.dim + (contrast == .increased && spotlight.dim > 0 ? 0.15 : 0), 0.88)
        let hole = spotlight.hotspotID
            .flatMap { Vocabulary.hotspot($0) }
            .map { $0.frame.scaled(scale).insetBy(dx: -8 * scale, dy: -8 * scale) }
        let shape = SpotlightVeil(hole: hole, in: size, cornerRadius: 26 * scale + 6)
        if reduceMotion {
            // No gliding: the old veil fades out as the new one fades in.
            shape
                .fill(Color.black.opacity(dim), style: FillStyle(eoFill: true))
                .id(spotlight.hotspotID ?? "none")
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            shape
                .fill(Color.black.opacity(dim), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func bubbles(scale: CGFloat, size: CGSize) -> some View {
        let language = settings.language
        let gender = settings.gender
        let place = experience.board.place
        if place == .ward, let line = experience.nurseLine {
            placed(
                SpeechBubble(text: line.text(language), voice: .other, width: bubbleWidth(size)),
                // Beside the nurse's face, in the doorway.
                at: ArtPoint(852, 176).scaled(scale),
                in: size,
                label: Copy.nurseSays.text(language) + Text(": ") + line.text(language)
            )
        }
        if let spoken = experience.board.spoken {
            placed(
                SpeechBubble(text: spoken.words.text(language, gender), voice: .person, width: bubbleWidth(size)),
                at: place.speakerAt.scaled(scale),
                in: size,
                label: Copy.youSaid.text(language) + Text(": ") + spoken.words.text(language, gender)
            )
            .id(spoken.serial)
            .transition(.opacity)
        } else if experience.showsSilence, place == .ward {
            placed(
                SpeechBubble(text: Copy.silence.text(language), voice: .person, width: 90),
                at: place.speakerAt.scaled(scale),
                in: size,
                label: Copy.silenceLabel.text(language)
            )
            .transition(.opacity)
        }
    }

    private func bubbleWidth(_ size: CGSize) -> CGFloat {
        min(300, max(150, size.width * 0.44))
    }

    /// Hangs a bubble from its speaker: the tail's tip on `anchor`, the box
    /// above it (or below, near the top edge) and slid sideways to stay in
    /// the room.
    ///
    /// The accessibility label goes on the bubble itself, before it is
    /// positioned: on the positioned view it would cover the whole room and
    /// hide every object from VoiceOver's touch exploration.
    private func placed(_ bubble: SpeechBubble, at anchor: CGPoint, in size: CGSize, label: Text) -> some View {
        let margin: CGFloat = 8
        let half = bubble.width / 2
        let lowest = half + margin
        let highest = max(size.width - half - margin, lowest)
        let boxCenter = min(max(anchor.x, lowest), highest)
        let tailUp = anchor.y < 96
        var shifted = bubble
        shifted.shift = boxCenter - anchor.x
        shifted.tailUp = tailUp
        return Color.clear
            .frame(width: 1, height: 1)
            .overlay(alignment: tailUp ? .top : .bottom) {
                shifted
                    .fixedSize()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(label)
            }
            .position(anchor)
            .allowsHitTesting(false)
    }

    private var pausedBadge: some View {
        Label {
            Copy.paused.text(settings.language)
        } icon: {
            Image(systemName: "pause.circle.fill")
        }
        .font(.system(.headline, design: .rounded, weight: .bold))
        .foregroundStyle(HolosTheme.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(HolosTheme.highlight, in: Capsule())
        .overlay { Capsule().strokeBorder(HolosTheme.keyline, lineWidth: 2) }
        .fixedSize()
        .allowsHitTesting(false)
    }
}

#Preview("Room canvas") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return RoomCanvas(isNarrow: false)
        .padding()
        .background(Color.black)
        .holos(services)
        .environment(experience)
        .onAppear { experience.start(isScanning: true) }
}
