import SwiftUI

/// Step 4: the whole conversation again, in Ukrainian.
///
/// Nothing is translated here. Every line kept its meaning in both
/// languages from the moment it was chosen, so the transcript simply
/// redraws itself in Ukrainian, and each of the person's answers is spoken
/// again in turn. The nurse's lines change language too, but stay silent:
/// the voice belongs only to the person.
///
/// Only the transcript changes language. The step, the explanation, the
/// status line and Continue stay in the judge's own language, so an
/// English-speaking judge can still read what is happening.
struct ReplayStep: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(Speaker.self) private var speaker
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.colorSchemeContrast) private var contrast

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let language = settings.language
        VStack(spacing: 14) {
            TopBar {
                StepHeader(step: Copy.step4, title: Copy.replayTitle, detail: Copy.replayBody)
            }
            ReplayVoiceNotice()
            // About twenty lines replay here, so the transcript stays
            // scrollable: a clean tap presses, a drag scrolls.
            ChatView(replayingID: experience.replayingLineID, language: .ukrainian)
                .pressOnTap(isActive: isScanning)
            // One press anywhere moves on, even in the middle of the replay;
            // the row with Continue is the big touch-down switch.
            statusRow(language)
                .switchTapArea(isActive: isScanning)
        }
        .padding(16)
        .onAppear {
            let story = experience
            hub.route { _ in story.replayPressed() }
            announce(Copy.step4(language), in: language)
        }
    }

    private func statusRow(_ language: Language) -> some View {
        HStack(spacing: 16) {
            Label {
                status.text(language)
                    .font(.bedside(.headline, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: experience.replayFinished ? "checkmark.circle.fill" : "speaker.wave.2.fill")
                    .accessibilityHidden(true)
            }
            .foregroundStyle(BedsideTheme.softInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            continueButton(language)
        }
    }

    /// Never claims Ukrainian speech the device cannot make: without the
    /// voice the answers are spoken in English, and the status says only
    /// that they are shown in Ukrainian.
    private var status: Bilingual {
        if experience.conversation.personLines.isEmpty {
            return Copy.replayNothing
        }
        if speaker.hasUkrainianVoice {
            return experience.replayFinished ? Copy.replayDone : Copy.replaySpeaking
        }
        return experience.replayFinished ? Copy.replayDoneShownOnly : Copy.replayShownOnly
    }

    /// Lit from the start, like every one-button screen: one press moves on,
    /// even in the middle of the replay.
    private func continueButton(_ language: Language) -> some View {
        Button {
            experience.replayPressed()
        } label: {
            Label {
                Copy.continueLabel.text(language)
                    .font(.bedside(.title2, weight: .bold))
            } icon: {
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 28)
            .frame(minWidth: 180, minHeight: 68)
            .background(BedsideTheme.personBubble(contrast), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isScanning, cornerRadius: 20)
        .opacity(experience.replayReady ? 1 : 0.6)
        .accessibilityLabel(Copy.continueLabel.text(language))
        .accessibilityHint(Copy.continueHint.text(language))
    }
}

/// "No Ukrainian voice", for step 4.
///
/// Core's `VoiceNotice` speaks up only while the board itself is in
/// Ukrainian. Here the screen stays in the judge's language while the
/// answers are said in Ukrainian, so this notice appears whenever the voice
/// is missing, written in whatever language the screen is in.
struct ReplayVoiceNotice: View {
    @Environment(HolosSettings.self) private var settings
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
                        CoreCopy.noUkrainianVoiceTitle.text(settings.language)
                            .font(.bedside(.headline, weight: .bold))
                        CoreCopy.noUkrainianVoiceBody.text(settings.language)
                            .font(.bedside(.subheadline))
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
        // Back from Settings with a freshly downloaded voice, the notice
        // clears without a relaunch.
        .onChange(of: scenePhase) {
            if scenePhase == .active { speaker.refreshVoices() }
        }
    }
}

#Preview("Step 4") {
    let experience = Experience.preview(.ukrainian)
    return ReplayStep()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}

#Preview("No Ukrainian voice notice") {
    ReplayVoiceNotice()
        .padding()
        .background(BedsideTheme.background)
        .holos(.preview())
}
