import SwiftUI

/// The paper card every part of the story is told on.
///
/// Paper-white with near-black ink over the dusk room, so the words are
/// the brightest thing on screen while they matter. Long text scrolls
/// rather than being cut, whatever the text size — but the footer (the
/// buttons, or "press to continue") is pinned below it, because a switch
/// user cannot scroll and must always see what the light is on.
///
/// In scanning mode the card is its own switch, edge to edge, rather than
/// sitting under the room's: a finger that lands on it presses, the way the
/// card says — yet text long enough to scroll can still be dragged.
struct CardShell<Content: View, Footer: View>: View {
    let isNarrow: Bool
    let content: Content
    let footer: Footer

    @Environment(Experience.self) private var experience
    @Environment(SwitchHub.self) private var hub
    @Environment(\.colorSchemeContrast) private var contrast

    init(isNarrow: Bool, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.isNarrow = isNarrow
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        let pad: CGFloat = isNarrow ? 18 : 26
        let isScanning = experience.isScanning
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                // It fits: the whole text is one big switch, like the room.
                inner(pad)
                    .switchTapArea(isActive: isScanning)
                // It scrolls: a drag must still move the text, so here a
                // press is a tap that lifts without moving.
                ScrollView { inner(pad) }
                    .simultaneousGesture(
                        TapGesture().onEnded { hub.press(.tap) },
                        including: isScanning ? .all : .subviews
                    )
            }
            footer
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, pad)
                .padding(.top, 14)
                .padding(.bottom, pad)
                // While scanning, the scan picks the footer's buttons, never
                // the finger: a touch presses whichever one is lit.
                .switchTapArea(isActive: isScanning)
        }
        .foregroundStyle(HolosTheme.ink)
        .frame(maxWidth: 680)
        .background(RoomTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(contrast == .increased ? HolosTheme.keyline : Color.black.opacity(0.08), lineWidth: contrast == .increased ? 3 : 1)
        }
        .shadow(color: .black.opacity(0.45), radius: 24, y: 10)
        .environment(\.colorScheme, .light)
    }

    private func inner(_ pad: CGFloat) -> some View {
        content
            .padding(.horizontal, pad)
            .padding(.top, pad)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A narrative card: a title, a few sentences, and how to move on.
struct StageCard: View {
    let title: Bilingual
    let message: Bilingual
    let isNarrow: Bool

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        CardShell(isNarrow: isNarrow) {
            VStack(alignment: .leading, spacing: 14) {
                title.text(language, gender)
                    .font(.system(isNarrow ? .title3 : .title2, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                message.text(language, gender)
                    .font(isNarrow ? .body : .title3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } footer: {
            ContinueFooter()
        }
    }
}

/// How to move on from a narrative card.
///
/// Scanning: the whole screen is the switch, so the card only says so —
/// and the words brighten once a press will count. Touch: a real button,
/// which is also what VoiceOver users reach.
struct ContinueFooter: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = settings.language
        if experience.isScanning {
            Label {
                Copy.pressToContinue.text(language)
            } icon: {
                Image(systemName: "hand.point.up.left.fill")
            }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(HolosTheme.ink.opacity(experience.canContinue ? 1 : 0.35))
            .padding(.top, 4)
            .animation(.easeIn(duration: 0.3), value: experience.canContinue)
        } else {
            Button {
                experience.continuePressed()
            } label: {
                Label {
                    Copy.continueButton.text(language)
                } icon: {
                    Image(systemName: "chevron.right")
                }
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 22)
                .frame(minHeight: 56)
                .background(HolosTheme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!experience.canContinue)
            .opacity(experience.canContinue ? 1 : 0.4)
            .accessibilityLabel(Copy.continueButton.text(language))
            .accessibilityHint(Copy.continueHint.text(language))
            .accessibilityInputLabels(Copy.continueButton.inputLabels)
        }
    }
}

/// A big button on a card that the card's own little scan visits.
struct CardButton: View {
    let id: String
    let title: Bilingual
    let symbol: String
    let hint: Bilingual
    var prominent = false
    /// The card's reading language, when it differs from the board's (the
    /// Ukrainian card). Nil follows the board.
    var language: Language? = nil

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = self.language ?? settings.language
        Button {
            experience.cardTouched(id)
        } label: {
            Label {
                title.text(language)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            } icon: {
                Image(systemName: symbol)
            }
            .foregroundStyle(prominent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(prominent ? HolosTheme.ink : WordKind.control.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(experience.cardLitID == id, cornerRadius: 16)
        .accessibilityLabel(title.text(language))
        .accessibilityHint(hint.text(language))
        .accessibilityInputLabels(title.inputLabels)
    }
}

#Preview("Stage card") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return StageCard(title: Copy.problemAskTitle, message: Copy.problemAskBody, isNarrow: false)
        .padding()
        .background(Color(red: 0.03, green: 0.10, blue: 0.12))
        .holos(services)
        .environment(experience)
}
