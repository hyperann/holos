import SwiftUI

/// Step 4, about 30 seconds: hear the person's own sentences in Ukrainian.
///
/// Each card shows the two choices that made the sentence — starter and
/// word — and then the sentence Holos actually says. Side by side, the gap
/// is the lesson: «Подзвоніть…» + «Дружина» is not «Подзвоніть, будь
/// ласка, моїй дружині», and only a stored, checked sentence gets it right.
///
/// These are the person's messages being replayed, so the synthesizer is
/// still only speaking for them. Without a Ukrainian voice on the device
/// the step is read, not heard: the cards are all there, a notice says why
/// nothing plays and how to add the voice, and Continue is the only choice.
struct UkrainianStep: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(Speaker.self) private var speaker
    @Environment(Feedback.self) private var feedback
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    @State private var scanner = Scanner()
    @State private var playing: Int?
    @State private var playback: Task<Void, Never>?
    @State private var settle: Task<Void, Never>?
    /// True once the screen has had its moment to land (see `start`).
    @State private var settled = false

    private static let continueID = "ukrainian.continue"
    private static let againID = "ukrainian.again"

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let language = settings.language
        let sentences = experience.sentencesForUkrainian
        // Read here, in this view's own body, so changes always redraw it.
        let playingIndex = playing
        let hasVoice = speaker.hasUkrainianVoice
        let isSettled = settled
        // Without a voice no scan runs here, so Continue is lit directly,
        // like Begin in step 1: it is what any press will do.
        let continueLit = scanner.isHighlighted(Self.continueID) || (!hasVoice && isScanning && isSettled)
        let againLit = scanner.isHighlighted(Self.againID)
        NarrativePage(isScanning: isScanning) {
            StepKicker(part: 4, title: Copy.ukrainianTitle)
            Copy.ukrainianHeadline.text(language)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Copy.ukrainianBody.text(language)
                .font(.title3)
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !hasVoice {
                noVoiceNotice
            }
            ForEach(Array(sentences.enumerated()), id: \.element.id) { index, phrase in
                SentenceCard(phrase: phrase, isPlaying: playingIndex == index)
            }
        } actions: {
            HStack(spacing: 12) {
                BigButton(
                    title: Copy.continueOn,
                    symbol: "chevron.right",
                    prominent: true,
                    isHighlighted: continueLit,
                    hint: Copy.continueHint
                ) {
                    feedback.select()
                    finish()
                }
                // Without a Ukrainian voice there is nothing to hear again,
                // and no one should land on a button that does nothing.
                if hasVoice {
                    BigButton(
                        title: Copy.hearAgain,
                        symbol: "speaker.wave.2.fill",
                        isHighlighted: againLit,
                        hint: Copy.hearAgainHint
                    ) {
                        feedback.select()
                        playAll(knockIfSilent: true)
                    }
                }
            }
        }
        .onAppear { start() }
        .onDisappear {
            scanner.stop()
            playback?.cancel()
            settle?.cancel()
        }
        .onChange(of: isScanning) {
            if isScanning, settled, speaker.hasUkrainianVoice { scanner.start() } else { scanner.stop() }
        }
        .onChange(of: speaker.hasUkrainianVoice) {
            // A voice added (or lost) while this screen is up: the scan must
            // offer exactly the buttons on screen.
            scanner.load(scanTree, start: isScanning && settled && speaker.hasUkrainianVoice)
        }
    }

    /// Core's `VoiceNotice` shows only while the board is in Ukrainian, and
    /// says speech falls back to English. Neither is true here: this page
    /// stays in the reader's language and only ever plays Ukrainian, so
    /// without the voice nothing plays — and the notice says exactly that.
    private var noVoiceNotice: some View {
        let language = settings.language
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "speaker.slash.fill")
                .font(.title2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                CoreCopy.noUkrainianVoiceTitle.text(language)
                    .font(.headline)
                Copy.noVoiceStep4.text(language)
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

    /// Continue is lit first: the sentences play by themselves, so one
    /// press is all a judge needs to move on. Without a voice there is
    /// nothing to hear again, so Continue stands alone.
    private var scanTree: [ScanNode] {
        if speaker.hasUkrainianVoice {
            return [ScanNode.item(Self.continueID), ScanNode.item(Self.againID)]
        }
        return [ScanNode.item(Self.continueID)]
    }

    private func start() {
        // The voice may have been added in Settings earlier in the session.
        speaker.refreshVoices()
        settled = false
        scanner.bind(to: services, label: { id in
            switch id {
            case Self.continueID: Copy.continueOn
            case Self.againID: Copy.hearAgain
            default: nil
            }
        }, onSelect: { id in
            if id == Self.continueID {
                finish()
            } else if id == Self.againID {
                playAll(knockIfSilent: true)
            }
        })
        // A two-button reading screen: the next step must always be one
        // press away. A judge who reads or listens past three quiet loops
        // would otherwise find the first press only wakes the scan.
        scanner.loopsBeforePause = .max
        scanner.load(scanTree, start: false)
        hub.route { _ in
            pressed()
        }
        announce(Copy.ukrainianTitle(settings.language), in: settings.language)
        settle?.cancel()
        settle = Task {
            // A moment to land, so a press meant for the last screen cannot
            // skip this one, and the voice does not start mid-transition.
            try? await Task.sleep(for: .seconds(1.0))
            guard !Task.isCancelled else { return }
            settled = true
            if isScanning, speaker.hasUkrainianVoice { scanner.start() }
            playAll(knockIfSilent: false)
        }
    }

    /// With a voice, a press works the two-button scan. Without one only
    /// Continue is left, so a press is Continue — as on every reading
    /// screen — rather than a one-cell scan ticking and re-announcing the
    /// same button at someone who is trying to read.
    private func pressed() {
        if speaker.hasUkrainianVoice {
            scanner.press()
        } else if settled, isScanning {
            feedback.select()
            finish()
        }
    }

    /// Plays every sentence in turn. `Speaker` cuts off whatever is
    /// speaking when asked to speak again, so each one waits for the last.
    ///
    /// - Parameter knockIfSilent: True for a chosen "Hear them again", where
    ///   a press that cannot be answered gets the gentle "not available"
    ///   knock. The automatic play as the screen opens stays quiet instead:
    ///   nobody asked for anything yet, and a knock for nothing reads as an
    ///   error.
    private func playAll(knockIfSilent: Bool) {
        playback?.cancel()
        guard speaker.hasUkrainianVoice else {
            if knockIfSilent { feedback.unavailable() }
            return
        }
        let gender = settings.gender
        let lines = experience.sentencesForUkrainian.map { $0.speech(.ukrainian, gender) }
        playback = Task {
            for (index, line) in lines.enumerated() {
                guard !Task.isCancelled else { return }
                playing = index
                feedback.speak()
                speaker.say(line, in: .ukrainian)
                try? await Task.sleep(for: .seconds(0.4))
                var waited = 0.0
                while speaker.isSpeaking, waited < 10, !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(0.15))
                    waited += 0.15
                }
                try? await Task.sleep(for: .seconds(0.5))
            }
            guard !Task.isCancelled else { return }
            playing = nil
        }
    }

    private func finish() {
        guard experience.step == .ukrainian else { return }
        playback?.cancel()
        settle?.cancel()
        speaker.stop()
        scanner.stop()
        experience.advance()
    }
}

/// One sentence: its English, the two choices that made it, and the
/// Ukrainian sentence Holos says.
private struct SentenceCard: View {
    let phrase: Phrase
    let isPlaying: Bool

    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let gender = settings.gender
        let frame = phrase.frameID.map { Vocabulary.frame($0) }
        VStack(alignment: .leading, spacing: 10) {
            phrase.speech.text(.english)
                .font(.headline)
                .foregroundStyle(WordsTheme.secondary(contrast))
            if let frame {
                HStack(spacing: 8) {
                    part(frame.starter, kind: frame.kind)
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WordsTheme.secondary(contrast))
                        .accessibilityHidden(true)
                    part(phrase.label, kind: phrase.kind)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "arrow.right")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isPlaying ? WordKind.action.ink : WordsTheme.secondary(contrast))
                    .accessibilityHidden(true)
                phrase.speech.text(.ukrainian, gender)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isPlaying ? HolosTheme.highlight : WordsTheme.rule.opacity(contrast == .increased ? 1 : 0.5),
                    lineWidth: isPlaying ? 4 : 1.5
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(phrase.speech.text(.english))
        .accessibilityValue(phrase.speech.text(.ukrainian, gender))
    }

    private func part(_ words: Bilingual, kind: WordKind) -> some View {
        words.text(.ukrainian, settings.gender)
            .font(.system(.headline, design: .serif, weight: .semibold))
            .foregroundStyle(HolosTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(kind.tint, in: Capsule())
    }
}

#Preview("Step 4 — Ukrainian") {
    UkrainianStep()
        .environment(Experience())
        .holos(.preview())
}
