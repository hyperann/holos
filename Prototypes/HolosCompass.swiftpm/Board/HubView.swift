import SwiftUI

/// The centre of the compass: the sentence so far, and Speak.
///
/// Three lines tell the whole story of a message as it grows. The trail
/// ("I feel › Pain › Head") says where you are; the draft in yellow ("My
/// head hurts…") says where the path is heading; below it, in white, is
/// everything already said. Choosing the centre says all of it again,
/// together — for the doctor who has just walked in.
struct HubView: View {
    let controller: CompassController
    var isLit = false
    var isGuide = false
    /// Where the needle points: the lit petal, or the pointed one.
    var needleTarget: Direction?
    let action: () -> Void

    @Environment(HolosSettings.self) private var settings
    @Environment(MessageBuilder.self) private var message
    @Environment(Speaker.self) private var speaker
    @Environment(\.colorSchemeContrast) private var contrast

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
    }

    var body: some View {
        let language = settings.language
        Button(action: action) {
            GeometryReader { geometry in
                let size = geometry.size
                let wide = size.width > size.height * 1.15
                Group {
                    if wide {
                        HStack(alignment: .center, spacing: 16) {
                            NeedleDial(target: needleTarget)
                                .frame(width: min(size.height * 0.62, size.width * 0.3, 150))
                            words
                        }
                    } else {
                        VStack(spacing: 10) {
                            NeedleDial(target: needleTarget)
                                .frame(height: min(size.width * 0.42, size.height * 0.28, 110))
                            words
                        }
                    }
                }
                .padding(14)
                .frame(width: size.width, height: size.height)
            }
            .background(CompassTheme.surface, in: shape)
            .overlay {
                shape.strokeBorder(CompassTheme.keyline(contrast), lineWidth: CompassTheme.keylineWidth(contrast))
            }
            .overlay(alignment: .topTrailing) {
                if isGuide {
                    GuideMarker()
                        .padding(10)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .scanHighlight(isLit, cornerRadius: 30)
        .accessibilityLabel(CoreCopy.speak.text(language))
        .accessibilityValue(messageText(language))
        .accessibilityHint(CoreCopy.speakHint.text(language))
        .accessibilityAddTraits(isLit ? .isSelected : [])
        .accessibilityInputLabels(CoreCopy.speak.inputLabels)
    }

    private var words: some View {
        let language = settings.language
        let gender = settings.gender
        return VStack(alignment: .leading, spacing: 6) {
            if !controller.crumbs.isEmpty {
                taggedText(controller.crumbs.map { $0(language, gender) }.joined(separator: " › "), language)
                    .font(CompassTheme.font(.subheadline, weight: .bold))
                    .foregroundStyle(CompassTheme.quietText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            if !controller.isHome {
                controller.level.draft.text(language, gender)
                    .font(CompassTheme.font(.title2))
                    .foregroundStyle(HolosTheme.highlight)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            messageText(language)
                .font(CompassTheme.font(message.isEmpty ? .title3 : .title2, weight: message.isEmpty ? .semibold : .heavy))
                .foregroundStyle(message.isEmpty ? CompassTheme.quietText : CompassTheme.text)
                .lineLimit(4)
                .minimumScaleFactor(0.4)
            Spacer(minLength: 0)
            if controller.scanner.state == .paused {
                Label {
                    Copy.Board.paused.text(language)
                } icon: {
                    Image(systemName: "pause.circle.fill")
                }
                .font(CompassTheme.font(.subheadline, weight: .bold))
                .foregroundStyle(CompassTheme.quietText)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            }
            speakPill(language)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func messageText(_ language: Language) -> Text {
        message.isEmpty
            ? CoreCopy.messageEmpty.text(language)
            : taggedText(message.text(language, settings.gender), language)
    }

    /// Turns yellow while the voice is speaking: a person who cannot hear
    /// well still sees that their words are out loud.
    private func speakPill(_ language: Language) -> some View {
        let speaking = speaker.isSpeaking
        return HStack(spacing: 8) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 18, weight: .bold))
            (speaking ? Copy.Board.speaking : CoreCopy.speak).text(language)
                .font(CompassTheme.font(.headline))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(HolosTheme.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(speaking ? HolosTheme.highlight : HolosTheme.paper, in: Capsule())
        .accessibilityHidden(true)
    }
}

#Preview("Hub") {
    let services = HolosServices.preview()
    let controller = CompassController()
    HubView(controller: controller, isLit: true, needleTarget: .east) {}
        .frame(width: 460, height: 260)
        .padding(30)
        .background(CompassTheme.background)
        .holos(services)
}
