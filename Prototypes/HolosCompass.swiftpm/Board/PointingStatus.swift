import SwiftUI

/// What head pointing is doing right now, in words and a ring.
///
/// Someone steering with their head cannot ask "is it working?", so this
/// always answers: off, asking for the camera, finding your centre, no face
/// (and the scan is carrying on), or which way you are pointing and how
/// long is left to hold.
struct PointingStatus: View {
    let pointer: HeadPointer
    /// On the board, also say what the person's one other press does.
    var pressHint: Bilingual?

    @Environment(SwitchHub.self) private var hub
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = settings.language
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(CompassTheme.quietText.opacity(0.35), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: pointer.progress)
                    .stroke(HolosTheme.highlight, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: pointer.direction?.arrowSymbol ?? "face.smiling")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(CompassTheme.text)
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                statusLine.text(language)
                    .font(CompassTheme.font(.headline, weight: .bold))
                if pointer.isPointing, let direction = pointer.direction {
                    Copy.Head.holding(direction).text(language)
                        .font(CompassTheme.font(.subheadline, weight: .semibold))
                        .foregroundStyle(HolosTheme.highlight)
                } else if pointer.isPointing, pointer.restProgress > 0 {
                    // Says why the board is about to change by itself.
                    Copy.Head.restingBack.text(language)
                        .font(CompassTheme.font(.subheadline, weight: .semibold))
                        .foregroundStyle(HolosTheme.highlight)
                }
                if pointer.isPointing, let pressHint {
                    pressHint.text(language)
                        .font(CompassTheme.font(.subheadline, weight: .medium))
                        .foregroundStyle(CompassTheme.quietText)
                }
            }
            .foregroundStyle(CompassTheme.text)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var statusLine: Bilingual {
        guard pointer.isOn else { return Copy.Head.off }
        let head = hub.head
        if head.isRunning, head.isCalibrating {
            return CoreCopy.headCalibrating
        }
        switch head.status {
        case .off, .asking:
            return CoreCopy.headAsking
        case .denied:
            return CoreCopy.headDenied
        case .noCamera:
            return CoreCopy.headNoCamera
        case .searching:
            return Copy.Head.fallback
        case .tracking:
            return Copy.Head.ready
        }
    }
}

#Preview("Pointing status") {
    let services = HolosServices.preview()
    PointingStatus(pointer: HeadPointer(), pressHint: Copy.Head.restBack)
        .padding(24)
        .background(CompassTheme.background)
        .holos(services)
}
