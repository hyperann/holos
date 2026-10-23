import SwiftUI

/// One line of the conversation.
///
/// The partner's words sit on the left in a plain card beside their
/// picture; the person's sit on the right, filled with colour, because
/// those are the words that were hard-won and are spoken aloud.
struct ChatBubble: View {
    let line: ChatLine
    /// True while the replay is saying this line again.
    var isReplaying = false
    /// Draws the words in this language instead of the board's. Step 4 shows
    /// the transcript in Ukrainian while everything around it — the step,
    /// the status, Continue, the role names — stays in the judge's language.
    var language: Language? = nil

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Group {
            switch line.role {
            case .note:
                note
            case .person:
                personBubble
            case .nurse, .partner:
                partnerBubble
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
    }

    private var wordsLanguage: Language {
        language ?? settings.language
    }

    /// Tagged with its language, so even text read straight off the screen
    /// (Speak Screen) gets a Ukrainian voice for Ukrainian words.
    private var text: Text {
        taggedText(line.words(wordsLanguage, settings.gender), wordsLanguage)
    }

    private var note: some View {
        text
            .font(.bedside(.subheadline, weight: .semibold))
            .italic()
            .foregroundStyle(BedsideTheme.softInk)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(BedsideTheme.background.opacity(0.8), in: Capsule())
            .frame(maxWidth: .infinity)
    }

    private var partnerBubble: some View {
        HStack(alignment: .bottom, spacing: 10) {
            PartnerAvatar(role: line.role)
            text
                .font(.bedside(.title3, weight: .semibold))
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    BedsideTheme.card,
                    in: UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 6, bottomTrailingRadius: 22, topTrailingRadius: 22, style: .continuous)
                )
                .overlay {
                    UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 6, bottomTrailingRadius: 22, topTrailingRadius: 22, style: .continuous)
                        .stroke(BedsideTheme.line(contrast), lineWidth: contrast == .increased ? 2 : 1)
                }
                .shadow(color: BedsideTheme.shadow, radius: 6, y: 3)
            Spacer(minLength: 36)
        }
    }

    private var personBubble: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Spacer(minLength: 36)
            HStack(spacing: 10) {
                if let faceLevel = line.faceLevel {
                    // The face the answer was chosen by, as on the scale.
                    PainFace(level: faceLevel)
                        .frame(width: 30, height: 30)
                } else if let symbol = line.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .bold))
                        .accessibilityHidden(true)
                }
                text
                    .font(.bedside(.title3, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                if isReplaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .bold))
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                BedsideTheme.personBubble(contrast),
                in: UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22, bottomTrailingRadius: 6, topTrailingRadius: 22, style: .continuous)
            )
            .shadow(color: BedsideTheme.shadow, radius: 6, y: 3)
            .scanHighlight(isReplaying, cornerRadius: 22)
        }
    }

    /// "Nurse: How are you feeling?" — the role in the board's language,
    /// the words tagged with theirs, so VoiceOver picks the right voice.
    private var accessibilityText: AttributedString {
        let language = settings.language
        let role: Bilingual?
        switch line.role {
        case .nurse: role = Copy.roleNurse
        case .partner: role = Copy.rolePartner
        case .person: role = Copy.roleYou
        case .note: role = nil
        }
        let words = line.words == Copy.nurseWaiting ? Copy.nurseWaitingSpoken : line.words
        var result = AttributedString()
        if let role {
            result.append(role.spoken(language))
            result.append(AttributedString(": "))
        }
        result.append(words.spoken(wordsLanguage, settings.gender))
        return result
    }
}

/// The partner's picture: simple shapes and a symbol, never a photo. The
/// nurse carries a stethoscope; any other partner is just a person.
struct PartnerAvatar: View {
    let role: ChatRole
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle()
                .fill(BedsideTheme.peach)
            Circle()
                .strokeBorder(BedsideTheme.rust, lineWidth: 2)
            Image(systemName: role == .nurse ? "stethoscope" : "person.fill")
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(BedsideTheme.rust)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The three dots that say "the nurse is about to answer".
struct TypingBubble: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            PartnerAvatar(role: .nurse)
            Group {
                if reduceMotion {
                    dots(lit: nil)
                } else {
                    TimelineView(.periodic(from: .now, by: 0.35)) { context in
                        let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.35)
                        dots(lit: tick % 3)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                BedsideTheme.card,
                in: UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 6, bottomTrailingRadius: 22, topTrailingRadius: 22, style: .continuous)
            )
            Spacer(minLength: 36)
        }
        .accessibilityHidden(true)
    }

    /// With Reduce Motion the dots simply sit still at even strength.
    private func dots(lit: Int?) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(BedsideTheme.rust)
                    .frame(width: 11, height: 11)
                    .opacity(lit.map { $0 == index ? 1 : 0.3 } ?? 0.6)
            }
        }
    }
}

#Preview("Bubbles") {
    let experience = Experience.preview()
    return VStack(spacing: 14) {
        ChatBubble(line: ChatLine(id: 0, role: .note, words: Copy.noteTenMinutes, symbol: nil))
        ChatBubble(line: ChatLine(id: 1, role: .nurse, words: Copy.nurseBack, symbol: nil))
        ChatBubble(line: ChatLine(id: 2, role: .person, words: Bilingual("I'm in pain.", uk: "Мені боляче."), symbol: "bandage.fill"), isReplaying: true)
        ChatBubble(line: ChatLine(id: 3, role: .person, words: Bilingual("A lot.", uk: "Сильно."), symbol: "thermometer.medium", faceLevel: 2), language: .ukrainian)
        TypingBubble()
    }
    .padding()
    .background(BedsideTheme.chatBackground)
    .environment(experience)
    .holos(experience.services)
}
