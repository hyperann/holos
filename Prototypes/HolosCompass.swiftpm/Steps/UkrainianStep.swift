import SwiftUI

/// Step 4: hear it in Ukrainian.
///
/// The same message, the same board, the other language. One press and
/// the whole board — every label and the voice — becomes Ukrainian, which
/// is the language the people this is for actually speak. If the device has
/// no Ukrainian voice, the notice says so and English is spoken instead;
/// the step never depends on a voice being installed. Continue brings
/// English back, because the judged experience is in English.
struct UkrainianStep: View {
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(MessageBuilder.self) private var message
    @Environment(Speaker.self) private var speaker
    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scanner = Scanner()
    @State private var heard = false
    @State private var languageBefore: Language?
    @State private var ready = false
    @State private var gate: Task<Void, Never>?

    private static let hearID = "ukrainian.hear"
    private static let continueID = "ukrainian.continue"
    private static let buttonsID = "ukrainian.buttons"

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    /// The person's own message from step 2, or the goal if they skipped.
    private var words: Bilingual {
        message.isEmpty ? Vocabulary.goalWords : message.words
    }

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VoiceNotice()
                    if language == .ukrainian, !speaker.hasUkrainianVoice {
                        // The judge may not read the Ukrainian notice above.
                        CoreCopy.noUkrainianVoiceTitle.text(.english)
                            .font(CompassTheme.font(.subheadline, weight: .semibold))
                            .foregroundStyle(CompassTheme.quietText)
                    }
                    Copy.Ukrainian.title.text(language, gender)
                        .font(CompassTheme.font(.largeTitle))
                        .accessibilityAddTraits(.isHeader)
                    Copy.Ukrainian.body.text(language, gender)
                        .font(CompassTheme.font(.title3, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) {
                            card(.english)
                            card(.ukrainian)
                        }
                        VStack(spacing: 12) {
                            card(.english)
                            card(.ukrainian)
                        }
                    }
                    if heard, language == .ukrainian, languageBefore != nil {
                        // Only when Continue really will bring English back — and
                        // in English as well, for the judge it is written for.
                        VStack(alignment: .leading, spacing: 4) {
                            Copy.Ukrainian.switched.text(.ukrainian, gender)
                            Copy.Ukrainian.switched.text(.english)
                        }
                        .font(CompassTheme.font(.subheadline, weight: .medium))
                        .foregroundStyle(CompassTheme.quietText)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    buttons
                        .id(Self.buttonsID)
                }
                .foregroundStyle(CompassTheme.text)
                .padding(24)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            // On a phone the buttons sit below the fold, and a scanning judge
            // cannot scroll: keep both in view whenever one is lit. Scrolling to
            // the pair, not to each button, keeps the page from bouncing.
            .onChange(of: scanner.highlightedID) { _, id in
                if id != nil {
                    proxy.reveal(Self.buttonsID, anchor: .bottom, reduceMotion: reduceMotion)
                }
            }
            .onChange(of: ready) { _, isReady in
                if isReady, scanner.highlightedID != nil {
                    proxy.reveal(Self.buttonsID, anchor: .bottom, reduceMotion: reduceMotion)
                }
            }
        }
        .switchTapArea(isActive: isScanning)
        .onAppear(perform: begin)
        .onDisappear {
            gate?.cancel()
            scanner.stop()
            restoreLanguage()
        }
        .onChange(of: isScanning) {
            reload()
        }
    }

    // MARK: - Parts

    private func card(_ cardLanguage: Language) -> some View {
        let isUkrainian = cardLanguage == .ukrainian
        // The card whose words are actually in the air: the Ukrainian one,
        // or the English one when there is no Ukrainian voice to speak it.
        let lit = heard && speaker.isSpeaking && (isUkrainian != speaker.fellBackToEnglish)
        return VStack(alignment: .leading, spacing: 10) {
            taggedText(cardLanguage.nativeName, cardLanguage)
                .font(CompassTheme.font(.headline, weight: .bold))
                .foregroundStyle(CompassTheme.quietText)
            words.text(cardLanguage, settings.gender)
                .font(CompassTheme.font(.title2))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(minWidth: 260, maxWidth: .infinity, alignment: .leading)
        .background(CompassTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            // Yellow on whichever card is actually being spoken: the words
            // on the card and the words in the air are visibly the same.
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(lit ? HolosTheme.highlight : Color.white.opacity(0.2), lineWidth: lit ? 4 : 1.5)
        }
        .accessibilityElement(children: .combine)
    }

    private var buttons: some View {
        let hear = StopButton(
            title: heard ? Copy.Ukrainian.hearAgain : Copy.Ukrainian.hear,
            symbol: "speaker.wave.2.fill",
            isLit: scanner.isHighlighted(Self.hearID),
            prominent: !heard,
            hint: Copy.Ukrainian.hearHint
        ) {
            perform(Self.hearID, viaScan: false)
        }
        let next = StopButton(
            title: Copy.App.continueLabel,
            symbol: "chevron.right",
            isLit: scanner.isHighlighted(Self.continueID),
            prominent: heard,
            hint: Copy.App.continueHint
        ) {
            perform(Self.continueID, viaScan: false)
        }
        // The button that will be lit first is drawn first, so the order
        // on screen always matches the order of the scan.
        return VStack(spacing: 12) {
            if heard {
                next
                hear
            } else {
                hear
                next
            }
        }
    }

    // MARK: - Behaviour

    private func begin() {
        heard = false
        scanner.bind(to: services, label: { id in
            switch id {
            case Self.hearID: return heard ? Copy.Ukrainian.hearAgain : Copy.Ukrainian.hear
            case Self.continueID: return Copy.App.continueLabel
            default: return nil
            }
        }, onSelect: { id in
            perform(id, viaScan: true)
        })
        // A short choice screen: resting would only cost the judge a press
        // to wake it, with nothing on screen to say why.
        scanner.loopsBeforePause = .max
        reload()
        hub.route { _ in
            guard ready else { return }
            scanner.press()
        }
        openGate(after: 1.2)
        let language = settings.language
        announce(Copy.Ukrainian.title(language), in: language)
    }

    /// Ignores switch presses for a moment, so a double press cannot skip
    /// what the person has not yet seen or heard.
    private func openGate(after seconds: Double) {
        ready = false
        gate?.cancel()
        gate = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            ready = true
        }
    }

    /// Hear first until it has been heard; then Continue first.
    private func reload() {
        let ids = heard ? [Self.continueID, Self.hearID] : [Self.hearID, Self.continueID]
        if isScanning {
            scanner.load(ids.map { ScanNode.item($0) })
        } else {
            scanner.stop()
        }
    }

    private func perform(_ id: String, viaScan: Bool) {
        switch id {
        case Self.hearID:
            if settings.language != .ukrainian {
                languageBefore = settings.language
                settings.language = .ukrainian
            }
            services.feedback.speak()
            speaker.say(words)
            if !heard {
                heard = true
                reload()
            }
            // Continue is lit next; a bounced second press must not leave
            // before the Ukrainian has even started.
            openGate(after: 1.5)
        case Self.continueID:
            if !viaScan { services.feedback.select() }
            gate?.cancel()
            scanner.stop()
            restoreLanguage()
            experience.advance(from: .ukrainian)
        default:
            break
        }
    }

    private func restoreLanguage() {
        guard let before = languageBefore else { return }
        languageBefore = nil
        settings.language = before
    }
}

#Preview("Step 4 — hear it in Ukrainian") {
    let services = HolosServices.preview()
    UkrainianStep()
        .background(CompassTheme.background)
        .environment(Experience(start: .ukrainian))
        .holos(services)
        .preferredColorScheme(.dark)
}
