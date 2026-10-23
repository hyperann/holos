import SwiftUI

/// Step 1: a nurse asks, and there is no way to answer.
///
/// No lecture about aphasia — the judge simply sits in the bed for twenty
/// seconds. The answer area is empty and grey; a press finds nothing but a
/// dull knock; the nurse is patient, then busy, then gone. Only then does
/// Holos appear.
struct ProblemStep: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var knock = false
    @State private var knockFade: Task<Void, Never>?

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        VStack(spacing: 14) {
            TopBar {
                StepHeader(step: Copy.step1, title: Copy.qFeeling, detail: Copy.problemSetup)
            }
            // The card covers only what lies under the top bar, so Settings
            // and the language toggle stay in reach while it is up.
            ZStack {
                SplitLayout {
                    // A clean tap presses; a drag scrolls back.
                    ChatView()
                        .pressOnTap(isActive: isScanning)
                } board: {
                    emptyReply
                        .switchTapArea(isActive: isScanning)
                }
                if experience.problemCardShown {
                    card
                        .transition(.opacity)
                }
            }
        }
        .padding(16)
        .animation(.easeInOut(duration: 0.4), value: experience.problemCardShown)
        .task { [experience] in await experience.runProblemScene() }
        .onAppear {
            let story = experience
            hub.route { _ in story.problemPressed() }
            let language = settings.language
            announce(Copy.step1(language), in: language)
        }
        .onChange(of: experience.deadPresses) {
            // The knock is shown as well as felt and heard: the grey box
            // darkens for a moment, then fades back. A fade, not movement,
            // so it stays under Reduce Motion. The short wait lets the dark
            // frame actually reach the screen before the fade starts.
            knock = true
            knockFade?.cancel()
            knockFade = Task {
                try? await Task.sleep(for: .seconds(0.15))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.5)) {
                    knock = false
                }
            }
        }
        .onDisappear { knockFade?.cancel() }
    }

    /// Where the answer would be, if there were any way to give one.
    private var emptyReply: some View {
        let language = settings.language
        let message = experience.deadPresses > 0 ? Copy.pressedInVain : Copy.replyEmpty
        return VStack(spacing: 18) {
            Copy.yourTurn.text(language)
                .font(.bedside(.title2, weight: .bold))
                .foregroundStyle(BedsideTheme.softInk)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            Image(systemName: "hand.raised.slash.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(BedsideTheme.softInk.opacity(0.5))
                .accessibilityHidden(true)
            message.text(language)
                .font(.bedside(.title3, weight: .semibold))
                .foregroundStyle(BedsideTheme.softInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.gray.opacity(knock ? 0.32 : 0.14),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    contrast == .increased ? HolosTheme.ink : Color.gray.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 8])
                )
        }
        // In touch mode a finger on the empty box gets the same dull knock
        // a switch does; in scanning mode the switch area over it catches it.
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { experience.problemPressed() }
        .accessibilityElement(children: .combine)
    }

    /// "Holos gives your answer a voice." The whole card and the dimmed room
    /// around it are one switch.
    private var card: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.3))
                .switchTapArea(isActive: isScanning)
                .accessibilityHidden(true)
            ViewThatFits(in: .vertical) {
                cardPanel
                    .switchTapArea(isActive: isScanning)
                // A small phone or very large text: the card scrolls, and a
                // clean tap anywhere on it still presses.
                ScrollView {
                    cardPanel
                        .frame(maxWidth: .infinity)
                }
                .pressOnTap(isActive: isScanning)
            }
            // VoiceOver and Switch Control stay on the card while it is up,
            // as they would in an alert.
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    /// The Continue button is lit from the start: lit means "a press does
    /// this", here as on the board.
    private var cardPanel: some View {
        let language = settings.language
        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(BedsideTheme.personBubble(contrast))
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 60, height: 60)
                .accessibilityHidden(true)
                Copy.cardTitle.text(language)
                    .font(.bedside(.largeTitle, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            Copy.cardBody.text(language)
                .font(.bedside(.title3))
                .foregroundStyle(BedsideTheme.softInk)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                experience.problemPressed()
            } label: {
                Label {
                    Copy.pressToAnswer.text(language)
                        .font(.bedside(.title2, weight: .bold))
                } icon: {
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(BedsideTheme.personBubble(contrast), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            // While scanning, a touch on the button is a switch press like
            // any other on the card (so it flashes and is debounced); the
            // button itself is for touch mode, VoiceOver and Switch Control.
            .allowsHitTesting(!isScanning)
            .scanHighlight(isScanning, cornerRadius: 20)
            .opacity(experience.problemCardReady ? 1 : 0.6)
            .accessibilityLabel(Copy.pressToAnswer.text(language))
            .accessibilityHint(Copy.pressToAnswerHint.text(language))
        }
        .padding(28)
        .frame(maxWidth: 620)
        .background(BedsideTheme.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: BedsideTheme.shadow, radius: 20, y: 8)
        .padding(12)
    }
}

#Preview("Step 1") {
    let experience = Experience.preview(.problem)
    return ProblemStep()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
