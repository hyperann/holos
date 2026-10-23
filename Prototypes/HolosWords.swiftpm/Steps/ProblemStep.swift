import SwiftUI

/// Step 1, about 25 seconds: feel the problem.
///
/// A nurse asks who to call. The answer is "my wife" — and the word is
/// drawn right there in the blank, blurred, out of reach. For the first
/// few seconds every press gets only a dull knock and a shake: you have a
/// button, you know the answer, and nothing comes. That is anomia. Then
/// the screen lets you begin. In touch mode, and under VoiceOver, a tap on
/// the scene gets the same knock, and the copy says "try to answer"
/// rather than "press one button".
struct ProblemStep: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(Feedback.self) private var feedback
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var ready = false
    @State private var tries = 0
    @State private var shake = 0.0
    @State private var readyTask: Task<Void, Never>?
    @State private var shakeTask: Task<Void, Never>?

    /// Long enough to read the nurse's question and try once; also the
    /// guard that stops a stray press skipping the scene.
    private static let readSeconds = 5.0

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        // Read here, in this view's own body, so changes always redraw it.
        let isReady = ready
        let hasTried = tries > 0
        let offset = shake
        let tryLine = hasTried ? Copy.problemNothing : (isScanning ? Copy.problemTry : Copy.problemTryTouch)
        NarrativePage(isScanning: isScanning) {
            StepKicker(part: 1, title: Copy.problemKicker)
            // The scene, in one stack so a finger can try to answer anywhere
            // on it. Same spacing as the page around it, so nothing moves.
            VStack(alignment: .leading, spacing: 20) {
                nurseBubble
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Copy.callMyStem.text(language, gender)
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(HolosTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    BlankSlot(width: 210, ghost: Copy.ghostWord)
                }
                .offset(x: offset)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Copy.withBlank(Copy.callMyStem).text(language, gender))
                Copy.problemTitle.text(language, gender)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Copy.problemBody.text(language, gender)
                    .font(.title3)
                    .foregroundStyle(HolosTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Copy.problemExample.text(language, gender)
                    .font(.callout)
                    .foregroundStyle(WordsTheme.secondary(contrast))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .triesToAnswer(!isScanning && !isReady) {
                pressed()
            }
        } actions: {
            if isReady {
                // Lit like a scanned cell: the one thing a press will do.
                BigButton(
                    title: isScanning ? Copy.problemBegin : Copy.begin,
                    symbol: "chevron.right",
                    prominent: true,
                    isHighlighted: isScanning,
                    hint: Copy.beginHint
                ) {
                    begin()
                }
            } else {
                Label {
                    tryLine.text(language, gender)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: hasTried ? "face.dashed" : "hand.point.up.left.fill")
                        .foregroundStyle(WordKind.control.ink)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .triesToAnswer(!isScanning) {
                    pressed()
                }
            }
        }
        .onAppear { start() }
        .onDisappear {
            readyTask?.cancel()
            shakeTask?.cancel()
        }
    }

    private var nurseBubble: some View {
        let language = settings.language
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cross.case.fill")
                .font(.title2)
                .foregroundStyle(WordKind.people.ink)
                .frame(width: 52, height: 52)
                .background(WordKind.people.tint, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Copy.nurseName.text(language)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(WordsTheme.secondary(contrast))
                Copy.nurseAsks.text(language)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(HolosTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(WordsTheme.rule.opacity(contrast == .increased ? 1 : 0.6), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func start() {
        // Every press lands here, from the first moment — the point is to
        // feel a press that produces nothing.
        hub.route { _ in
            pressed()
        }
        announce(Copy.problemTitle(settings.language), in: settings.language)
        readyTask?.cancel()
        readyTask = Task {
            try? await Task.sleep(for: .seconds(Self.readSeconds))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                ready = true
            }
            // "Press anywhere" is only true while scanning. Under VoiceOver
            // and in touch mode there is a Begin button to choose instead.
            let line = isScanning ? Copy.problemBegin : Copy.problemReady
            announce(line(settings.language), in: settings.language)
        }
    }

    private func pressed() {
        if ready {
            begin()
            return
        }
        tries += 1
        feedback.unavailable()
        nudge()
    }

    private func begin() {
        // A second quick press must not skip the next screen too.
        guard experience.step == .problem else { return }
        readyTask?.cancel()
        feedback.select()
        experience.advance()
    }

    /// A small "no" shake. With Reduce Motion the dull knock, the press
    /// flash and the changed line under the scene carry it instead.
    private func nudge() {
        guard !reduceMotion else { return }
        shakeTask?.cancel()
        shakeTask = Task {
            for offset in [14.0, -11.0, 7.0, -4.0, 0.0] {
                withAnimation(.easeOut(duration: 0.06)) {
                    shake = offset
                }
                try? await Task.sleep(for: .seconds(0.06))
                guard !Task.isCancelled else { return }
            }
        }
    }
}

private extension View {
    /// Lets a finger try to answer, too. In touch mode and under VoiceOver
    /// there is no whole-screen switch, and a tap on the scene that did
    /// nothing at all — not even the knock — would teach nothing. Off while
    /// scanning: there the page's own switch area already takes the press,
    /// and a second tap gesture underneath would only compete with it.
    func triesToAnswer(_ isOn: Bool, action: @escaping () -> Void) -> some View {
        contentShape(Rectangle())
            .gesture(TapGesture().onEnded { action() }, including: isOn ? .all : .subviews)
    }
}

#Preview("Step 1 — the problem") {
    ProblemStep()
        .environment(Experience())
        .holos(.preview())
}
