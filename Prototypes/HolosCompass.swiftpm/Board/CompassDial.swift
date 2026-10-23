import SwiftUI

/// The board: four petals at north, east, south and west around the hub.
///
/// It only draws. Which stop is lit comes from the controller's scanner —
/// or, in head-pointing mode, from the head — and every tap goes back to
/// the controller, so scanning, touch and pointing all share one set of
/// rules about what a choice does.
struct CompassDial: View {
    let controller: CompassController
    var pointer: HeadPointer?
    /// The stop the guided step wants marked "Next".
    var guideID: String?
    var showsChips = true

    @Environment(HolosSettings.self) private var settings
    @Environment(MessageBuilder.self) private var message

    var body: some View {
        GeometryReader { geometry in
            let metrics = DialMetrics(size: geometry.size, showsChips: showsChips)
            let narrowSides = metrics.sideWidth < DialMetrics.narrowPetal
            let narrowMiddle = metrics.midWidth < DialMetrics.narrowPetal
            VStack(spacing: metrics.gap) {
                petal(.north, narrow: narrowMiddle)
                    .frame(width: metrics.midWidth, height: metrics.petalHeight)
                HStack(spacing: metrics.gap) {
                    petal(.west, narrow: narrowSides)
                        .frame(width: metrics.sideWidth, height: metrics.middleHeight)
                    centre(metrics)
                        .frame(width: metrics.midWidth, height: metrics.middleHeight)
                    petal(.east, narrow: narrowSides)
                        .frame(width: metrics.sideWidth, height: metrics.middleHeight)
                }
                petal(.south, narrow: narrowMiddle)
                    .frame(width: metrics.midWidth, height: metrics.petalHeight)
                if metrics.chipsBelow {
                    // On a phone the centre is too narrow for two chips side
                    // by side — both titles would shrink to "…", including
                    // "Yes, clear all". Below the cross they get the full width.
                    chips
                        .frame(width: geometry.size.width, height: metrics.chipHeight)
                        .accessibilitySortPriority(2)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            // A new level's petals fade in. Opacity only, so it is the
            // same with Reduce Motion on.
            .animation(.easeOut(duration: 0.2), value: controller.trail)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - What is lit

    private var isPointing: Bool { pointer?.isPointing ?? false }

    private func isLit(_ id: String) -> Bool {
        controller.scanner.isHighlighted(id)
    }

    private func isLit(_ direction: Direction) -> Bool {
        if isPointing {
            return pointer?.direction == direction
        }
        return isLit(direction.stopID)
    }

    /// The needle follows the head when it points, and the scan otherwise.
    private var needleTarget: Direction? {
        if isPointing {
            return pointer?.direction
        }
        return controller.scanner.highlightedID.flatMap { Direction(stopID: $0) }
    }

    // MARK: - Parts

    private func petal(_ direction: Direction, narrow: Bool) -> some View {
        let choice = controller.level.choice(direction)
        let progress = isPointing && pointer?.direction == direction ? (pointer?.progress ?? 0) : 0
        return PetalView(
            choice: choice,
            direction: direction,
            isLit: isLit(direction),
            isGuide: guideID == direction.stopID,
            pointProgress: progress,
            isFlashing: controller.flashID == choice.id,
            isNarrow: narrow
        ) {
            controller.activate(direction.stopID, via: .touch)
        }
        .id(choice.id)
        .transition(.opacity)
        // VoiceOver reads the ring in scan order: north, east, south, west,
        // then the centre — not the top-to-bottom order of the layout.
        .accessibilitySortPriority(sortPriority(direction))
    }

    private func sortPriority(_ direction: Direction) -> Double {
        switch direction {
        case .north: 7
        case .east: 6
        case .south: 5
        case .west: 4
        }
    }

    private func centre(_ metrics: DialMetrics) -> some View {
        VStack(spacing: metrics.gap) {
            HubView(
                controller: controller,
                isLit: isLit(CompassStop.hub),
                isGuide: guideID == CompassStop.hub,
                needleTarget: needleTarget
            ) {
                controller.activate(CompassStop.hub, via: .touch)
            }
            .accessibilitySortPriority(3)
            if showsChips, !metrics.chipsBelow {
                chips
                    .frame(height: metrics.chipHeight)
                    .accessibilitySortPriority(2)
            }
        }
    }

    /// Never more than two chips, in the order the scan visits them.
    private var chips: some View {
        let language = settings.language
        let confirming = controller.scanner.isEntered(CompassStop.clear)
        // A head resting in the middle below home is heading for Back.
        let restProgress = isPointing ? (pointer?.restProgress ?? 0) : 0
        return HStack(spacing: 10) {
            if !controller.isHome {
                HubChip(
                    title: CoreCopy.goBack,
                    symbol: "arrow.uturn.backward",
                    isLit: isLit(CompassStop.back),
                    isGuide: guideID == CompassStop.back,
                    hint: CoreCopy.goBackHint,
                    progress: restProgress
                ) {
                    controller.activate(CompassStop.back, via: .touch)
                }
                if controller.offersBackToStart {
                    HubChip(
                        title: Copy.Board.backToStart,
                        symbol: "arrow.counterclockwise",
                        isLit: isLit(CompassStop.backToStart),
                        hint: Copy.Board.backToStartHint
                    ) {
                        controller.activate(CompassStop.backToStart, via: .touch)
                    }
                }
            } else if confirming {
                // Inside the scanned Clear: "No, keep it" is lit first, so a
                // doubled or late press keeps the message; "Yes, clear all"
                // comes a full step later. Only scanning ever opens this.
                HubChip(
                    title: CoreCopy.clearCancel,
                    symbol: "arrow.uturn.backward",
                    isLit: isLit(CompassStop.clearCancel)
                ) {
                    controller.activate(CompassStop.clearCancel, via: .touch)
                }
                HubChip(
                    title: CoreCopy.clearConfirm,
                    symbol: "checkmark.circle.fill",
                    isLit: isLit(CompassStop.clearConfirm)
                ) {
                    controller.activate(CompassStop.clearConfirm, via: .touch)
                }
            } else {
                HubChip(
                    title: Copy.Board.switchTo(language.other),
                    symbol: "globe",
                    isLit: isLit(CompassStop.language),
                    isGuide: guideID == CompassStop.language,
                    spokenTitle: CoreCopy.languageLabel,
                    valueText: taggedText(language.nativeName, language),
                    hint: CoreCopy.languageHint
                ) {
                    controller.activate(CompassStop.language, via: .touch)
                }
                if !message.isEmpty {
                    HubChip(
                        title: CoreCopy.clear,
                        symbol: "xmark",
                        isLit: isLit(CompassStop.clear),
                        isGuide: guideID == CompassStop.clear
                    ) {
                        controller.activate(CompassStop.clear, via: .touch)
                    }
                }
            }
        }
    }
}

/// Sizes for the cross-shaped layout, from the space available.
///
/// The side petals take about a quarter of the width each and the top and
/// bottom ones about a quarter of the height, so on an iPad in landscape
/// every petal is the size of a hand — readable and hittable from a bed —
/// and on a phone in portrait it still fits without scrolling. There the
/// centre is too narrow for its chips, so they move to a row of their own
/// under the cross.
private struct DialMetrics {
    /// Below this a petal cannot carry both its "Next" tag and its arrow.
    static let narrowPetal: CGFloat = 160
    /// Below this the centre cannot hold two chips side by side.
    static let narrowCentre: CGFloat = 240

    let gap: CGFloat
    let petalHeight: CGFloat
    let middleHeight: CGFloat
    let midWidth: CGFloat
    let sideWidth: CGFloat
    let chipHeight: CGFloat
    /// True when the chips sit in a full-width row under the cross.
    let chipsBelow: Bool

    init(size: CGSize, showsChips: Bool) {
        let width = max(size.width, 0)
        let height = max(size.height, 0)
        gap = min(width, height) < 500 ? 8 : 14
        sideWidth = max(min(width * 0.27, 340), min(76, width / 4))
        midWidth = max(width - 2 * sideWidth - 2 * gap, 0)
        chipsBelow = showsChips && midWidth < Self.narrowCentre
        let rowHeight: CGFloat = 60
        // The row below takes its height from the cross, not from the hub.
        let crossHeight = max(height - (chipsBelow ? rowHeight + gap : 0), 0)
        petalHeight = max(crossHeight * 0.24, 0)
        middleHeight = max(crossHeight - 2 * petalHeight - 2 * gap, 0)
        if !showsChips {
            chipHeight = 0
        } else if chipsBelow {
            chipHeight = rowHeight
        } else {
            chipHeight = min(max(middleHeight * 0.22, 56), 72)
        }
    }
}

#Preview("Compass, landscape") {
    let services = HolosServices.preview()
    let controller = CompassController()
    CompassDial(controller: controller, guideID: Direction.west.stopID)
        .frame(width: 1100, height: 600)
        .padding()
        .background(CompassTheme.background)
        .holos(services)
}

#Preview("Compass, phone") {
    let services = HolosServices.preview()
    let controller = CompassController()
    CompassDial(controller: controller)
        .frame(width: 360, height: 560)
        .padding()
        .background(CompassTheme.background)
        .holos(services)
}
