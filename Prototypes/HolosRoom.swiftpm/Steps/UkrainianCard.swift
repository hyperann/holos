import SwiftUI

/// Part 4: the same message, now in Ukrainian.
///
/// Pressing "Say it in Ukrainian" switches the whole board — every pill in
/// the room behind the card relabels — and speaks the person's own message
/// from part 2. The card itself stays in the judge's language, so the
/// explanation, the buttons and the voice notice are always readable. Both
/// languages of the message stay on the card, so a judge without a
/// Ukrainian voice still sees exactly what would be said, and the notice
/// explains how to add one.
struct UkrainianCard: View {
    let isNarrow: Bool

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        // The board's language decides which line of the message is "now";
        // the reading language is the judge's own.
        let boardLanguage = settings.language
        let reading = experience.readingLanguage
        let gender = settings.gender
        let words = Bilingual.joined(experience.ukrainianMessage.map(\.speech))
        CardShell(isNarrow: isNarrow) {
            VStack(alignment: .leading, spacing: 14) {
                Copy.ukrainianTitle.text(reading)
                    .font(.system(isNarrow ? .title3 : .title2, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Copy.ukrainianBody.text(reading)
                    .font(isNarrow ? .body : .title3)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 6) {
                    messageLine(words, in: .english, gender: gender, isCurrent: boardLanguage == .english)
                    messageLine(words, in: .ukrainian, gender: gender, isCurrent: boardLanguage == .ukrainian)
                }
                if experience.saidInUkrainian {
                    Copy.ukrainianAfter.text(reading)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } footer: {
            VStack(alignment: .leading, spacing: 12) {
                MissingVoiceNotice(language: reading)
                buttons(in: reading)
            }
        }
    }

    @ViewBuilder
    private func buttons(in language: Language) -> some View {
        let say = CardButton(
            id: RoomIDs.sayUkrainian,
            title: experience.saidInUkrainian ? Copy.sayAgain : Copy.sayInUkrainian,
            symbol: "speaker.wave.2.fill",
            hint: Copy.sayInUkrainianHint,
            prominent: true,
            language: language
        )
        let next = CardButton(
            id: RoomIDs.cardContinue,
            title: Copy.continueButton,
            symbol: "chevron.right",
            hint: Copy.continueHint,
            language: language
        )
        if isNarrow {
            VStack(spacing: 10) {
                say
                next
            }
        } else {
            HStack(spacing: 12) {
                say
                next
            }
        }
    }

    private func messageLine(_ words: Bilingual, in lineLanguage: Language, gender: SpeakerGender, isCurrent: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            taggedText(lineLanguage.shortName, lineLanguage)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(isCurrent ? Color.white : HolosTheme.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isCurrent ? HolosTheme.ink : WordKind.control.tint, in: Capsule())
            words.text(lineLanguage, gender)
                .font(.system(isCurrent ? .title2 : .title3, design: .rounded, weight: isCurrent ? .bold : .regular))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? RoomTheme.voice : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Core's voice notice, in a language the judge can read.
///
/// Core's `VoiceNotice` speaks the board's language and appears only once
/// the board is Ukrainian — on this card that would mean an English-
/// speaking judge meets "how to add a Ukrainian voice" only in Ukrainian.
/// This one uses Core's words in the card's reading language, and shows
/// before the press too, so the judge knows in advance why they may hear
/// English.
struct MissingVoiceNotice: View {
    let language: Language

    @Environment(Speaker.self) private var speaker
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !speaker.hasUkrainianVoice {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "speaker.slash.fill")
                        .font(.title2)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        CoreCopy.noUkrainianVoiceTitle.text(language)
                            .font(.headline)
                        CoreCopy.noUkrainianVoiceBody.text(language)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(HolosTheme.ink)
                .padding(14)
                .background(WordKind.people.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
        // Coming back from Settings with a freshly downloaded voice should
        // clear the notice without a relaunch.
        .onChange(of: scenePhase) {
            if scenePhase == .active { speaker.refreshVoices() }
        }
    }
}

#Preview("Ukrainian card") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return UkrainianCard(isNarrow: false)
        .padding()
        .background(Color(red: 0.03, green: 0.10, blue: 0.12))
        .holos(services)
        .environment(experience)
}

#Preview("Missing voice notice") {
    MissingVoiceNotice(language: .english)
        .padding()
        .holos(.preview())
}
