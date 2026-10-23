import SwiftUI

/// Step 1: feel the problem.
///
/// The nurse asks a simple question, and the judge — standing in for
/// Oleksandr — has one button. Pressing it does exactly what one press
/// alone can do for him: nothing anyone can understand. The second press
/// turns the page to the idea that answers it.
struct ProblemStep: View {
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var tried = false
    /// Presses are ignored until the screen has been on long enough to
    /// read, so a double press cannot skip a screen nobody saw.
    @State private var ready = false
    @State private var gate: Task<Void, Never>?
    @State private var dimmed = false
    @State private var undim: Task<Void, Never>?

    private static let footerID = "problem.footer"

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    bedside
                    VStack(alignment: .leading, spacing: 10) {
                        Copy.Problem.title.text(language, gender)
                            .font(CompassTheme.font(.largeTitle))
                            .accessibilityAddTraits(.isHeader)
                        Copy.Problem.body.text(language, gender)
                            .font(CompassTheme.font(.title3, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Copy.Problem.example.text(language, gender)
                            .font(CompassTheme.font(.body, weight: .medium))
                            .foregroundStyle(CompassTheme.quietText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Copy.Problem.prompt.text(language, gender)
                        .font(CompassTheme.font(.title3, weight: .bold))
                        .foregroundStyle(HolosTheme.highlight)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer(minLength: 0)
                        oneButton
                        Spacer(minLength: 0)
                    }
                    if tried {
                        VStack(alignment: .leading, spacing: 10) {
                            Copy.Problem.nothing.text(language, gender)
                                .font(CompassTheme.font(.title2))
                            Copy.Problem.turn.text(language, gender)
                                .font(CompassTheme.font(.title3, weight: .semibold))
                                .foregroundStyle(CompassTheme.quietText)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                    }
                    footer
                        .id(Self.footerID)
                }
                .foregroundStyle(CompassTheme.text)
                .padding(24)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            // The payoff ("…That is the compass.") appears below the button and
            // can land under the fold, where a scanning judge cannot scroll.
            .onChange(of: tried) { _, isTried in
                if isTried {
                    proxy.reveal(Self.footerID, anchor: .bottom, reduceMotion: reduceMotion)
                }
            }
        }
        .switchTapArea(isActive: isScanning)
        .onAppear(perform: begin)
        .onDisappear {
            gate?.cancel()
            undim?.cancel()
        }
    }

    // MARK: - Parts

    /// The scene: the nurse's question in a bubble, and the person's
    /// answer — an empty one.
    private var bedside: some View {
        let language = settings.language
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                portrait("stethoscope", tint: WordKind.people.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Copy.Problem.nurseName.text(language)
                        .font(CompassTheme.font(.subheadline, weight: .bold))
                        .foregroundStyle(CompassTheme.quietText)
                    Copy.Problem.nurseQuestion.text(language)
                        .font(CompassTheme.font(.title2))
                        .foregroundStyle(HolosTheme.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(HolosTheme.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            HStack(alignment: .top, spacing: 12) {
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    Copy.Problem.youName.text(language)
                        .font(CompassTheme.font(.subheadline, weight: .bold))
                        .foregroundStyle(CompassTheme.quietText)
                    Text(verbatim: "…")
                        .font(CompassTheme.font(.title2))
                        .foregroundStyle(CompassTheme.quietText)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(CompassTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .opacity(tried ? 1 : 0.35)
                }
                portrait("bed.double.fill", tint: WordKind.describing.tint)
            }
            .accessibilityHidden(true)
        }
        .padding(18)
        .background(CompassTheme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func portrait(_ symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(HolosTheme.ink)
            .frame(width: 56, height: 56)
            .background(tint, in: Circle())
            .accessibilityHidden(true)
    }

    /// The one movement. A real button for touch and VoiceOver; in scanning
    /// mode the whole screen is this button anyway.
    private var oneButton: some View {
        let language = settings.language
        let title = tried ? Copy.App.continueLabel : Copy.Problem.button
        return Button {
            hub.press(.tap)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: tried ? "chevron.right" : "hand.point.up.left.fill")
                    .font(.system(size: 40, weight: .bold))
                    .accessibilityHidden(true)
                title.text(language)
                    .font(CompassTheme.font(.title2))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(HolosTheme.ink)
            .frame(width: 170, height: 170)
            .background(tried ? WordKind.action.tint : HolosTheme.paper, in: Circle())
            .overlay { Circle().strokeBorder(HolosTheme.keyline, lineWidth: 4) }
            .contentShape(Circle())
            // An opacity dip, not a shake: the press visibly lands on
            // nothing, and Reduce Motion needs no special case.
            .opacity(dimmed ? 0.45 : 1)
            .animation(.easeOut(duration: 0.15), value: dimmed)
        }
        .buttonStyle(.plain)
        .scanHighlight(ready, cornerRadius: 85)
        .accessibilityLabel(title.text(language))
        .accessibilityHint((tried ? Copy.App.continueHint : Copy.Problem.buttonHint).text(language))
        .accessibilityInputLabels(title.inputLabels)
    }

    private var footer: some View {
        let language = settings.language
        let line: Bilingual = tried ? Copy.Problem.pressAgain : (isScanning ? Copy.App.pressAnywhere : Copy.Problem.buttonHint)
        return line.text(language)
            .font(CompassTheme.font(.headline, weight: .bold))
            .foregroundStyle(CompassTheme.quietText)
            .frame(maxWidth: .infinity)
            .opacity(ready ? 1 : 0.4)
            .accessibilityHidden(true)
    }

    // MARK: - Behaviour

    private func begin() {
        tried = false
        hub.route { _ in
            handlePress()
        }
        openGate(after: 2.0)
        let language = settings.language
        announce(Copy.Problem.title(language) + ". " + Copy.Problem.nurseQuestion(language), in: language)
    }

    private func handlePress() {
        guard ready else { return }
        let language = settings.language
        if tried {
            gate?.cancel()
            services.feedback.select()
            experience.advance(from: .problem)
            return
        }
        // The dull "nothing" knock: haptic and sound, with the dip and the
        // empty bubble as the visual.
        services.feedback.unavailable()
        withAnimation(.easeInOut(duration: 0.3)) {
            tried = true
        }
        dimmed = true
        undim?.cancel()
        undim = Task {
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            dimmed = false
        }
        openGate(after: 1.5)
        announce(Copy.Problem.nothing(language) + " " + Copy.Problem.turn(language), in: language)
    }

    private func openGate(after seconds: Double) {
        ready = false
        gate?.cancel()
        gate = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            ready = true
        }
    }
}

#Preview("Step 1 — the problem") {
    let services = HolosServices.preview()
    ProblemStep()
        .background(CompassTheme.background)
        .environment(Experience())
        .holos(services)
        .preferredColorScheme(.dark)
}
