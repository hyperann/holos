import SwiftUI

/// Step 1: feel the problem.
///
/// A nurse asks how you are. You understand her perfectly and can answer
/// with nothing but one press — and on this screen a press reaches no one:
/// it knocks dully and the nurse keeps asking. Nothing here is usable yet,
/// on purpose. Then Holos is named, and the same press becomes "begin".
struct ProblemStep: View {
    @Environment(Experience.self) private var experience

    var body: some View {
        let language = experience.language
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    NurseScene(line: Copy.nurseLine(experience.nurseLine))
                    VStack(alignment: .leading, spacing: 12) {
                        Copy.problemPersona.text(language)
                            .font(GridTheme.rounded(.title2))
                            .foregroundStyle(GridTheme.navy)
                        Copy.problemBody.text(language)
                            .font(.title3)
                            .foregroundStyle(HolosTheme.ink)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if experience.problemRevealed {
                        Copy.problemReveal.text(language)
                            .font(GridTheme.rounded(.title))
                            .foregroundStyle(GridTheme.navy)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: 720)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            BigSwitch()
                .padding(.vertical, 20)
        }
        .animation(.easeInOut(duration: 0.4), value: experience.problemRevealed)
        .narrativeTapArea()
    }
}

/// The nurse, drawn from shapes and a symbol, and what she says.
///
/// She speaks only in the bubble. The synthesiser in Holos is the person's
/// own voice, so it never speaks for anyone else.
private struct NurseScene: View {
    let line: Bilingual

    @Environment(Experience.self) private var experience

    var body: some View {
        let language = experience.language
        HStack(alignment: .center, spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(WordKind.people.tint)
                    .frame(width: 104, height: 104)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(WordKind.people.ink)
                    }
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 38, height: 38)
                    .background(WordKind.urgent.ink, in: Circle())
            }
            .accessibilityHidden(true)

            HStack(spacing: 0) {
                // The bubble's tail: a turned square tucked under the bubble.
                Rectangle()
                    .fill(GridTheme.card)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(45))
                    .offset(x: 11)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Copy.nurse.text(language)
                        .font(GridTheme.rounded(.subheadline, .semibold))
                        .foregroundStyle(GridTheme.quietInk)
                    line.text(language)
                        .font(GridTheme.rounded(.title, .semibold))
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(line)
                        .transition(.opacity)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .frame(minWidth: 220, alignment: .leading)
                .background(GridTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .animation(.easeInOut(duration: 0.3), value: line)
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity)
    }
}

/// The one big round switch. A tap anywhere on the screen presses too, so it
/// is mostly a picture of the switch — but VoiceOver users press it directly.
private struct BigSwitch: View {
    @Environment(Experience.self) private var experience
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pressed = false
    @State private var release: Task<Void, Never>?

    var body: some View {
        let language = experience.language
        let revealed = experience.problemRevealed
        let title = revealed ? Copy.switchBegin : Copy.switchLabel
        Button {
            hub.press(.tap)
        } label: {
            ZStack {
                Circle()
                    .fill(GridTheme.navy)
                Circle()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 6)
                    .padding(10)
                VStack(spacing: 6) {
                    Image(systemName: revealed ? "play.fill" : "hand.point.up.left.fill")
                        .font(.system(size: 38, weight: .bold))
                        .accessibilityHidden(true)
                    title.text(language)
                        .font(GridTheme.rounded(.title2, .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(Color.white)
                .padding(24)
            }
            .frame(width: 168, height: 168)
            // Pressing dips the switch; with Reduce Motion it brightens instead.
            .scaleEffect(pressed && !reduceMotion ? 0.93 : 1)
            .brightness(pressed && reduceMotion ? 0.2 : 0)
            .animation(.easeOut(duration: 0.12), value: pressed)
        }
        .buttonStyle(.plain)
        .scanHighlight(revealed, cornerRadius: 84)
        .accessibilityLabel(title.text(language))
        .accessibilityHint(Copy.switchHint.text(language))
        .accessibilityInputLabels(title.inputLabels)
        .onChange(of: hub.pressCount) {
            pressed = true
            release?.cancel()
            release = Task {
                try? await Task.sleep(for: .seconds(0.15))
                guard !Task.isCancelled else { return }
                pressed = false
            }
        }
        .onDisappear { release?.cancel() }
    }
}

#Preview("Step 1 — the problem") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.problem)
    return ProblemStep()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
