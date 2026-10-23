import SwiftUI

/// Under the room: "Show me" when it is offered, the other room, the other
/// language, and the message strip.
///
/// They come in the same order the scan visits them after the room's
/// objects, so the light moves down and across the screen the way the eye
/// does. While a story card is up they dim and stop answering touches.
struct BottomBar: View {
    let isNarrow: Bool

    @Environment(Experience.self) private var experience

    var body: some View {
        let inert = experience.boardMode == .inert
        Group {
            if isNarrow {
                VStack(spacing: 8) {
                    HStack(spacing: 8) { chips }
                    MessageStrip(isNarrow: true)
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    chips
                    MessageStrip(isNarrow: false)
                }
            }
        }
        .disabled(inert)
        .opacity(inert ? 0.5 : 1)
        // Behind a story card these cannot be used, so VoiceOver skips them
        // and goes straight to the card.
        .accessibilityHidden(inert)
    }

    @ViewBuilder
    private var chips: some View {
        let place = experience.board.place
        if experience.helpOffered, experience.boardMode == .guided {
            RoomChip(
                id: RoomIDs.helpChip,
                symbol: "hand.point.up.left.fill",
                title: Copy.helpChip,
                hint: Copy.helpChipHint,
                isNarrow: isNarrow
            )
        }
        RoomChip(
            id: RoomIDs.sceneChip,
            symbol: place.switchSymbol,
            title: place.switchLabel,
            hint: Copy.placeChipHint,
            isNarrow: isNarrow
        )
        RoomChip(
            id: RoomIDs.languageChip,
            symbol: "globe",
            title: Copy.languageChip,
            hint: CoreCopy.languageHint,
            isNarrow: isNarrow,
            showsOtherLanguage: true
        )
    }
}

/// A big square button under the room that the scan also visits.
struct RoomChip: View {
    let id: String
    let symbol: String
    let title: Bilingual
    let hint: Bilingual
    let isNarrow: Bool
    /// Adds the other language's own short name ("УКР"), so someone who
    /// reads only Ukrainian can still find their way to it.
    var showsOtherLanguage = false

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        let isLit = experience.litID == id
        let isGuide = experience.guideID == id
        let maxWidth: CGFloat = isNarrow ? .infinity : 118
        let other = language.other
        Button {
            experience.touched(id)
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.system(size: 21, weight: .bold))
                    if showsOtherLanguage {
                        taggedText(other.shortName, other)
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2), in: Capsule())
                    }
                }
                title.text(language, gender)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: maxWidth, minHeight: isNarrow ? 56 : 64)
            .background(RoomTheme.chip(contrast), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RoomTheme.outline(contrast), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isLit, cornerRadius: 16)
        .overlay(alignment: .top) {
            if isGuide {
                GuideMarker().offset(y: -26)
            }
        }
        // Chrome stops growing at the first accessibility size, so a phone
        // still has room for the room; the Large Content Viewer shows the
        // chip big instead, as Core's MessageBar does.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityLabel(title.text(language, gender))
        .accessibilityHint(hint.text(language))
        .accessibilityValue(isGuide ? Copy.nextStep.text(language) : Text(""))
        .accessibilityInputLabels(title.inputLabels)
        .accessibilityShowsLargeContentViewer {
            Label {
                title.text(language, gender)
            } icon: {
                Image(systemName: symbol)
            }
        }
    }
}

#Preview("Bottom bar") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return VStack(spacing: 30) {
        BottomBar(isNarrow: false)
        BottomBar(isNarrow: true).frame(width: 370)
    }
    .padding()
    .background(Color(red: 0.03, green: 0.10, blue: 0.12))
    .holos(services)
    .environment(experience)
    .onAppear { experience.go(to: .free) }
}
