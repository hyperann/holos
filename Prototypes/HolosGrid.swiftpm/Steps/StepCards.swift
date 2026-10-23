import SwiftUI

/// The card that opens steps 2 and 3: who, what for, and the goal — read
/// once with the board standing still behind it, so the scan never starts
/// flashing while someone is still reading.
struct IntroCard: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = experience.language
        let gender = settings.gender
        let isAphasia = experience.step == .aphasia
        VStack(alignment: .leading, spacing: 16) {
            (isAphasia ? Copy.aphasiaTitle : Copy.oneSwitchTitle).text(language)
                .font(GridTheme.rounded(.largeTitle))
                .foregroundStyle(GridTheme.navy)
                .accessibilityAddTraits(.isHeader)
            Group {
                if isAphasia {
                    Copy.aphasiaStory.text(language)
                        .font(.title3)
                    Copy.aphasiaPoint.text(language)
                        .font(.title3.weight(.semibold))
                } else {
                    (experience.modeIsScanning ? Copy.oneSwitchHowScanning : Copy.oneSwitchHowTouch).text(language)
                        .font(.title3)
                    if experience.modeIsScanning {
                        Copy.oneSwitchTip.text(language)
                            .font(.body)
                            .foregroundStyle(GridTheme.quietInk)
                    }
                }
            }
            .foregroundStyle(HolosTheme.ink)
            .fixedSize(horizontal: false, vertical: true)

            if let guide = experience.board.guide {
                VStack(alignment: .leading, spacing: 6) {
                    Copy.goalSay.text(language)
                        .font(.headline)
                        .foregroundStyle(GridTheme.navy)
                    Copy.quoted(guide.sentence).text(language, gender)
                        .font(GridTheme.rounded(.title))
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if isAphasia {
                        Copy.aphasiaRoute.text(language)
                            .font(GridTheme.rounded(.headline, .semibold))
                            .foregroundStyle(GridTheme.navy)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WordKind.describing.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityElement(children: .combine)
            }

            HStack {
                Spacer(minLength: 0)
                ContinueButton(title: Copy.pressToStart)
            }
        }
        .gridCard(padding: 24)
    }
}

/// "You said it": the sentence, and what it cost — in presses when
/// scanning, because that number is the whole argument for switch access.
///
/// It never claims more than happened. After "Show me" it says Holos built
/// the message, with no press count; a message that is not the goal (a
/// quick phrase, say) gets a plain "You said it." and its words, without
/// the "whole sentence" lines that only the goal has earned.
struct SuccessCard: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = experience.language
        let earned = !experience.usedShowMe && experience.saidTheGoal
        VStack(alignment: .leading, spacing: 14) {
            Label {
                experience.successTitle.text(language)
                    .font(GridTheme.rounded(.title))
                    .foregroundStyle(GridTheme.navy)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(WordKind.action.ink)
                    .accessibilityHidden(true)
            }
            .accessibilityAddTraits(.isHeader)
            if let words = experience.spokenWords {
                // In the board's language: this is what the person said.
                Copy.quoted(words).text(settings.language, settings.gender)
                    .font(GridTheme.rounded(.title2, .semibold))
                    .foregroundStyle(HolosTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(WordKind.action.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            if earned {
                if experience.modeIsScanning, let presses = experience.finalPresses, presses > 0 {
                    Copy.successPresses(presses).text(language)
                        .font(.title3)
                        .foregroundStyle(HolosTheme.ink)
                } else {
                    Copy.successTouch.text(language)
                        .font(.title3)
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // Step 3's head-turn invitation follows on its own screen, so
            // both steps continue the same way.
            HStack {
                Spacer(minLength: 0)
                ContinueButton()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gridCard(padding: 24)
    }
}

/// Step 4: the first message again, now in Ukrainian.
///
/// The card's own words stay in the judge's language; only the message and
/// the board behind it change. If the device has no Ukrainian voice, the
/// Speaker says it in English and this card explains why — in words the
/// judge can read, not in the Ukrainian the board is showing.
struct UkrainianCard: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(Speaker.self) private var speaker
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let language = experience.language
        let gender = settings.gender
        let message = Copy.quoted(Bilingual.joined(experience.firstMessage.map(\.speech)))
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Copy.ukrainianTitle.text(language)
                    .font(GridTheme.rounded(.largeTitle))
                    .foregroundStyle(GridTheme.navy)
            } icon: {
                Image(systemName: "globe")
                    .foregroundStyle(GridTheme.navy)
                    .accessibilityHidden(true)
            }
            .accessibilityAddTraits(.isHeader)
            Copy.ukrainianBody.text(language)
                .font(.title3)
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundStyle(GridTheme.navy)
                        .opacity(speaker.isSpeaking ? 1 : 0.35)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: speaker.isSpeaking)
                        .accessibilityHidden(true)
                    message.text(.ukrainian, gender)
                        .font(GridTheme.rounded(.largeTitle))
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // The line an English-only judge depends on, so it gets full
                // reading contrast rather than the system's faint grey.
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Copy.ukrainianGloss.text(language)
                    message.text(.english)
                }
                .font(.body)
                .foregroundStyle(GridTheme.quietInk)
                .accessibilityElement(children: .combine)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WordKind.people.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

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
                }
                .foregroundStyle(HolosTheme.ink)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityElement(children: .combine)
            }

            HStack {
                Spacer(minLength: 0)
                ContinueButton()
            }
        }
        .gridCard(padding: 24)
    }
}

#Preview("Intro — step 3") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.aphasia, phase: .intro)
    return IntroCard()
        .padding()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}

#Preview("Success — step 2") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.oneSwitch, phase: .done)
    return SuccessCard()
        .padding()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}

#Preview("Step 4 — Ukrainian") {
    let services = HolosServices.preview()
    let experience = Experience(services: services, persistsTourState: false)
    experience.showForPreview(.ukrainian)
    return UkrainianCard()
        .padding()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
