import SwiftUI

/// Step 2: four choices, any sentence.
///
/// The goal is a real bedside message — "My head hurts a lot. I need
/// medicine, please." — and the only tool is one switch. Each press goes
/// one level deeper and the path itself builds the sentence; reaching a
/// sentence says it at once, because for the people this is for, every
/// press saved is effort saved.
///
/// It cannot be failed. A "Next" marker sits on the choice that leads on,
/// and moves to Back if the person wanders. Saying anything at all counts
/// in the end, and after 45 quiet seconds a "Move on" stop appears.
struct ComposeStep: View {
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(MessageBuilder.self) private var message
    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var controller = CompassController()
    @State private var said: Set<String> = []
    @State private var keptCount = 0
    @State private var done = false
    @State private var reachedGoal = false
    /// False until something has actually been spoken, so a judge who moved
    /// on without a word is never told "You said it".
    @State private var spokeAnything = false
    @State private var offerMoveOn = false
    @State private var stuckTimer: Task<Void, Never>?
    @State private var ready = false
    @State private var gate: Task<Void, Never>?
    @State private var pressesAtStart = 0
    @State private var pressesUsed = 0

    private static let moveOnID = "compose.moveOn"
    /// Long enough to try properly; short enough that a judge who is lost
    /// is never lost for long.
    private static let stuckSeconds = 45.0

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    private var nextGoal: String? {
        Vocabulary.goalLeafIDs.first { !said.contains($0) }
    }

    var body: some View {
        VStack(spacing: 12) {
            VoiceNotice()
            GeometryReader { geometry in
                let wide = geometry.size.width > geometry.size.height * 1.2
                if wide {
                    HStack(alignment: .top, spacing: 20) {
                        goalScroller
                            .frame(width: min(360, geometry.size.width * 0.3))
                        dial
                    }
                } else if done {
                    VStack(spacing: 12) {
                        goalCard
                        // On a short phone screen the finished card needs
                        // the room more than the dimmed board does.
                        if geometry.size.height > 640 {
                            dial
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        // The card keeps its natural height while it fits its
                        // share of the screen. Taller than that (the largest
                        // text sizes), it scrolls in a box 40% high, so the
                        // board always keeps most of the space.
                        ViewThatFits(in: .vertical) {
                            goalCard
                            goalScroller
                                .frame(height: geometry.size.height * 0.4)
                        }
                        dial
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .switchTapArea(isActive: isScanning)
        .onAppear(perform: begin)
        .onDisappear {
            controller.stop()
            stuckTimer?.cancel()
            gate?.cancel()
        }
        .onChange(of: isScanning) { _, scanning in
            controller.setScanning(scanning)
        }
    }

    // MARK: - Parts

    private var dial: some View {
        CompassDial(
            controller: controller,
            pointer: experience.pointer,
            guideID: done ? nil : nextGoal.flatMap { controller.guide(toward: $0) }
        )
        .opacity(done ? 0.45 : 1)
        .animation(.easeOut(duration: 0.3), value: done)
    }

    /// The goal card in a scroll view. Scanning makes the whole screen the
    /// switch, so nobody can scroll it by finger: when "Move on" appears or
    /// is lit, it is brought into view.
    private var goalScroller: some View {
        ScrollViewReader { proxy in
            ScrollView {
                goalCard
            }
            .onChange(of: offerMoveOn) { _, offered in
                if offered {
                    proxy.reveal(Self.moveOnID, anchor: .bottom, reduceMotion: reduceMotion)
                }
            }
            .onChange(of: controller.scanner.highlightedID) { _, id in
                if id == Self.moveOnID {
                    proxy.reveal(Self.moveOnID, anchor: .bottom, reduceMotion: reduceMotion)
                }
            }
        }
    }

    private var goalCard: some View {
        let language = settings.language
        let gender = settings.gender
        return VStack(alignment: .leading, spacing: 12) {
            Copy.Compose.goalTitle.text(language)
                .font(CompassTheme.font(.headline, weight: .bold))
                .foregroundStyle(CompassTheme.quietText)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(Vocabulary.goalLeafIDs.enumerated()), id: \.element) { index, id in
                goalLine(index: index, id: id)
            }
            if done {
                doneSection
            } else {
                // At the accessibility text sizes the how-to would push the
                // two goal sentences out of sight; the goal matters more,
                // and VoiceOver hears it in the step's announcement.
                if !dynamicTypeSize.isAccessibilitySize {
                    (isScanning ? Copy.Compose.howToScan : Copy.Compose.howToTouch).text(language, gender)
                        .font(CompassTheme.font(.subheadline, weight: .medium))
                        .foregroundStyle(CompassTheme.quietText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if offerMoveOn {
                    Copy.Compose.stuck.text(language)
                        .font(CompassTheme.font(.subheadline, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    StopButton(
                        title: Copy.Compose.moveOn,
                        symbol: "chevron.right",
                        isLit: controller.scanner.isHighlighted(Self.moveOnID),
                        hint: Copy.Compose.moveOnHint
                    ) {
                        // Through the controller, so a touch gets the same
                        // haptic and sound as a scanned choice.
                        controller.activate(Self.moveOnID, via: .touch)
                    }
                    .id(Self.moveOnID)
                }
            }
        }
        .foregroundStyle(CompassTheme.text)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CompassTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func goalLine(index: Int, id: String) -> some View {
        let language = settings.language
        let isSaid = said.contains(id)
        let words = Vocabulary.tree.choice(id: id)?.words ?? Bilingual("", uk: "")
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: isSaid ? "checkmark.circle.fill" : "\(index + 1).circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(isSaid ? WordKind.action.tint : CompassTheme.quietText)
                .accessibilityHidden(true)
            words.text(language, settings.gender)
                .font(CompassTheme.font(.title3))
                .foregroundStyle(isSaid ? WordKind.action.tint : CompassTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue((isSaid ? Copy.Compose.said : Copy.Compose.notYet).text(language))
    }

    /// What the finished card says: praise only for words actually spoken.
    private var doneWords: (title: Bilingual, body: Bilingual) {
        guard spokeAnything else {
            return (Copy.Compose.movedOnTitle, Copy.Compose.movedOnBody)
        }
        return (Copy.Compose.doneTitle, reachedGoal ? Copy.Compose.doneGoal : Copy.Compose.doneOther)
    }

    private var doneSection: some View {
        let language = settings.language
        let words = doneWords
        return VStack(alignment: .leading, spacing: 12) {
            words.title.text(language)
                .font(CompassTheme.font(.title))
                .foregroundStyle(WordKind.action.tint)
            words.body.text(language)
                .font(CompassTheme.font(.title3, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            if pressesUsed > 0 {
                Label {
                    Copy.Compose.presses(pressesUsed).text(language)
                } icon: {
                    Image(systemName: "hand.point.up.left.fill")
                }
                .font(CompassTheme.font(.headline, weight: .bold))
                .foregroundStyle(CompassTheme.quietText)
            }
            StopButton(
                title: Copy.App.continueLabel,
                symbol: "chevron.right",
                isLit: ready,
                prominent: true,
                hint: Copy.App.continueHint
            ) {
                hub.press(.tap)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Behaviour

    private func begin() {
        spokeAnything = false
        services.message.clear()
        controller.attach(services: services, pointer: experience.pointer)
        controller.extraLabel = { id in
            id == Self.moveOnID ? Copy.Compose.moveOn : nil
        }
        controller.onEvent = { event in
            handle(event)
        }
        controller.goHome()
        controller.start(scanning: isScanning)
        hub.route { source in
            if done {
                guard ready else { return }
                continueOn()
            } else {
                controller.press(source)
            }
        }
        pressesAtStart = hub.pressCount
        restartStuckTimer()
        let language = settings.language
        announce(Copy.Compose.goalTitle(language) + ": " + Vocabulary.goalWords(language, settings.gender), in: language)
    }

    private func handle(_ event: CompassEvent) {
        guard !done else { return }
        switch event {
        case .said(let id, let kept):
            spokeAnything = true
            if Vocabulary.goalLeafIDs.contains(id) {
                said.insert(id)
            }
            if kept { keptCount += 1 }
            restartStuckTimer()
            if Vocabulary.goalLeafIDs.allSatisfy({ said.contains($0) }) {
                finish(goal: true)
            } else if keptCount >= 3 {
                // Three sentences of their own: they have the idea, and the
                // goal was only ever an example.
                finish(goal: false)
            }
        case .spokeMessage:
            spokeAnything = true
            // Speaking the whole message from the centre is a deliberate
            // act, so it counts as finishing whatever the message says.
            if keptCount >= 1 {
                finish(goal: Vocabulary.goalLeafIDs.allSatisfy { said.contains($0) })
            }
        case .extra(let id):
            if id == Self.moveOnID {
                finish(goal: false)
            }
        }
    }

    private func finish(goal: Bool) {
        guard !done else { return }
        reachedGoal = goal
        pressesUsed = max(hub.pressCount - pressesAtStart, 0)
        controller.stop()
        stuckTimer?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            done = true
        }
        ready = false
        gate?.cancel()
        gate = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            ready = true
        }
        let language = settings.language
        let words = doneWords
        announce(words.title(language) + " " + words.body(language), in: language)
    }

    private func continueOn() {
        gate?.cancel()
        services.feedback.select()
        experience.advance(from: .compose)
    }

    private func restartStuckTimer() {
        stuckTimer?.cancel()
        stuckTimer = Task {
            try? await Task.sleep(for: .seconds(Self.stuckSeconds))
            guard !Task.isCancelled, !done else { return }
            offerMoveOn = true
            controller.setExtraStops([Self.moveOnID])
        }
    }
}

#Preview("Step 2 — four choices") {
    let services = HolosServices.preview()
    ComposeStep()
        .background(CompassTheme.background)
        .environment(Experience(start: .compose))
        .holos(services)
        .preferredColorScheme(.dark)
}
