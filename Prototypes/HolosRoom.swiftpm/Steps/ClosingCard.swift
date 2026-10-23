import SwiftUI

/// The one closing screen: who Holos is for, why it is free, private and
/// open — and two ways on: keep talking in the room, or start again.
///
/// "Keep talking" is lit first. The free room after the story is the real
/// app, and that is where a judge who has a minute left should end up.
struct ClosingCard: View {
    let isNarrow: Bool

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = settings.language
        CardShell(isNarrow: isNarrow) {
            VStack(alignment: .leading, spacing: 12) {
                Copy.closingTitle.text(language)
                    .font(.system(isNarrow ? .title3 : .title2, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                paragraph(Copy.closingWho, symbol: "person.2.fill")
                paragraph(Copy.closingWhy, symbol: "brain.head.profile")
                paragraph(Copy.closingFree, symbol: "heart.fill")
                Copy.closingSource.text(language)
                    .font(.footnote)
                    .foregroundStyle(HolosTheme.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        } footer: {
            buttons
        }
    }

    private func paragraph(_ words: Bilingual, symbol: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(WordKind.describing.ink)
                .accessibilityHidden(true)
            words.text(settings.language)
                .font(isNarrow ? .body : .title3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        let keep = CardButton(
            id: RoomIDs.keepTalking,
            title: Copy.keepTalking,
            symbol: "bubble.left.and.bubble.right.fill",
            hint: Copy.keepTalkingHint,
            prominent: true
        )
        let again = CardButton(
            id: RoomIDs.startAgain,
            title: Copy.startAgain,
            symbol: "arrow.counterclockwise",
            hint: Copy.startAgainHint
        )
        if isNarrow {
            VStack(spacing: 10) {
                keep
                again
            }
        } else {
            HStack(spacing: 12) {
                keep
                again
            }
        }
    }
}

#Preview("Closing card") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return ClosingCard(isNarrow: false)
        .padding()
        .background(Color(red: 0.03, green: 0.10, blue: 0.12))
        .holos(services)
        .environment(experience)
}
