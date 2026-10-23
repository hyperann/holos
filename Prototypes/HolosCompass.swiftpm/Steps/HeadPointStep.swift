import SwiftUI

/// Step 3 (optional): point with your head.
///
/// Compass builds its own panel here instead of Core's `HeadTryPanel`,
/// because what it shows is different: not a head *switch* that presses,
/// but a head that *points* at one of four choices and holds. Skip is lit
/// first, so a judge who does not want the camera moves on with one press;
/// the camera turns on only when asked and off again when the step ends.
/// Like every narrative screen, it ignores presses for a moment after it
/// appears, so a double press on step 2's Continue cannot skip it unseen.
struct HeadPointStep: View {
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Only draws the home level; it never runs, so it chooses nothing.
    @State private var display = CompassController()
    @State private var panel = Scanner()
    @State private var succeeded = false
    @State private var chosen: Direction?
    @State private var finishing: Task<Void, Never>?
    @State private var ready = false
    @State private var gate: Task<Void, Never>?

    private static let skipID = "head.skip"
    private static let toggleID = "head.toggle"
    private static let swapLeftRightID = "head.swapLeftRight"
    private static let swapUpDownID = "head.swapUpDown"
    private static let recenterID = "head.recenter"

    private var pointer: HeadPointer { experience.pointer }

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > geometry.size.height * 1.2
            if wide {
                HStack(alignment: .top, spacing: 20) {
                    panelScroller
                        .frame(width: min(460, geometry.size.width * 0.42))
                    dial
                }
            } else {
                VStack(spacing: 12) {
                    panelScroller
                        .frame(maxHeight: geometry.size.height * 0.55)
                    dial
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .switchTapArea(isActive: isScanning)
        .onAppear(perform: begin)
        .onDisappear {
            finishing?.cancel()
            gate?.cancel()
            panel.stop()
            pointer.turnOff()
        }
        .onChange(of: isScanning) {
            reloadPanel()
        }
        .onChange(of: pointer.isOn) {
            reloadPanel()
        }
    }

    // MARK: - Parts

    /// Scanning makes the whole screen the switch, so a finger cannot
    /// scroll this panel; on a phone its buttons run below the fold. The lit
    /// one is brought into view instead, so nobody ever chooses blind.
    private var panelScroller: some View {
        ScrollViewReader { proxy in
            ScrollView {
                panelContent
            }
            .onChange(of: panel.highlightedID) { _, id in
                if let id {
                    proxy.reveal(id, anchor: .center, reduceMotion: reduceMotion)
                }
            }
        }
    }

    private var dial: some View {
        CompassDial(
            controller: display,
            pointer: pointer,
            guideID: succeeded ? nil : Direction.north.stopID,
            showsChips: false
        )
        .allowsHitTesting(false)
        // The panel says everything this picture shows; the picture alone
        // would only be four buttons that do nothing here.
        .accessibilityHidden(true)
    }

    private var panelContent: some View {
        let language = settings.language
        let gender = settings.gender
        return VStack(alignment: .leading, spacing: 14) {
            Copy.Head.title.text(language)
                .font(CompassTheme.font(.title))
                .accessibilityAddTraits(.isHeader)
            Copy.Head.body.text(language, gender)
                .font(CompassTheme.font(.body, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Copy.Head.tryIt.text(language, gender)
                .font(CompassTheme.font(.body, weight: .bold))
                .foregroundStyle(HolosTheme.highlight)
                .fixedSize(horizontal: false, vertical: true)
            Copy.Head.optional.text(language)
                .font(CompassTheme.font(.footnote, weight: .medium))
                .foregroundStyle(CompassTheme.quietText)
                .fixedSize(horizontal: false, vertical: true)
            if pointer.isOn {
                PointingStatus(pointer: pointer)
            }
            if succeeded, let chosen {
                Label {
                    Copy.Head.success(Vocabulary.home.choice(chosen).label).text(language, gender)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .font(CompassTheme.font(.title3))
                .foregroundStyle(HolosTheme.ink)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WordKind.action.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            if isScanning, panel.state == .paused {
                Label {
                    Copy.Board.paused.text(language)
                } icon: {
                    Image(systemName: "pause.circle.fill")
                }
                .font(CompassTheme.font(.subheadline, weight: .bold))
                .foregroundStyle(CompassTheme.quietText)
            }
            StopButton(
                title: succeeded ? Copy.App.continueLabel : CoreCopy.headTrySkip,
                symbol: "chevron.right",
                isLit: panel.isHighlighted(Self.skipID),
                prominent: succeeded,
                hint: Copy.App.continueHint
            ) {
                perform(Self.skipID, viaScan: false)
            }
            .id(Self.skipID)
            StopButton(
                title: pointer.isOn ? Copy.Head.disable : Copy.Head.enable,
                symbol: pointer.isOn ? "xmark.circle.fill" : "face.smiling",
                isLit: panel.isHighlighted(Self.toggleID),
                hint: Copy.Board.headPointingHint
            ) {
                perform(Self.toggleID, viaScan: false)
            }
            .id(Self.toggleID)
            if pointer.isOn {
                StopButton(
                    title: Copy.Head.swapLeftRight,
                    symbol: "arrow.left.arrow.right",
                    isLit: panel.isHighlighted(Self.swapLeftRightID),
                    hint: Copy.Head.swapHint
                ) {
                    perform(Self.swapLeftRightID, viaScan: false)
                }
                .id(Self.swapLeftRightID)
                StopButton(
                    title: Copy.Head.swapUpDown,
                    symbol: "arrow.up.arrow.down",
                    isLit: panel.isHighlighted(Self.swapUpDownID),
                    hint: Copy.Head.swapHint
                ) {
                    perform(Self.swapUpDownID, viaScan: false)
                }
                .id(Self.swapUpDownID)
                StopButton(
                    title: CoreCopy.headRecenter,
                    symbol: "arrow.counterclockwise",
                    isLit: panel.isHighlighted(Self.recenterID),
                    hint: CoreCopy.headRecenterHint
                ) {
                    perform(Self.recenterID, viaScan: false)
                }
                .id(Self.recenterID)
            }
        }
        .foregroundStyle(CompassTheme.text)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CompassTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Behaviour

    private func begin() {
        succeeded = false
        chosen = nil
        panel.bind(to: services, label: { id in
            label(for: id)
        }, onSelect: { id in
            perform(id, viaScan: true)
        })
        pointer.onChoose = { direction in
            pointed(direction)
        }
        // Only the home level is drawn here, so resting has nowhere to go
        // back to (a board from an earlier step may have left its own rule).
        pointer.onRestBack = nil
        pointer.restBackAllowed = { false }
        reloadPanel()
        hub.route { source in
            guard ready else { return }
            // While pointing is on, a head turn is the pointing itself, never
            // a press on the panel — or looking left would press Skip. With
            // pointing off, Core's head switch is an ordinary switch here,
            // so someone using only their head can still Skip or turn
            // pointing on.
            if source == .head, pointer.isOn { return }
            panel.press()
        }
        ready = false
        gate?.cancel()
        gate = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            ready = true
        }
        let language = settings.language
        announce(Copy.Head.title(language), in: language)
    }

    /// Skip (or Continue) is always first, so one press always moves on.
    private func reloadPanel() {
        // A deferred change — the camera turning off as the step ends — must
        // not restart this panel on a screen that is already leaving, where
        // it would tick and click on through step 4.
        guard experience.step == .headPoint else {
            panel.stop()
            return
        }
        var ids = [Self.skipID, Self.toggleID]
        if pointer.isOn {
            ids += [Self.swapLeftRightID, Self.swapUpDownID, Self.recenterID]
        }
        // Without pointing this is a short choice screen, and resting would
        // only cost the judge a press to wake it. With pointing on, the
        // panel rests after three quiet loops, so it does not tick and click
        // at someone who is steering with their head.
        panel.loopsBeforePause = pointer.isOn ? 3 : Int.max
        if isScanning {
            panel.load(ids.map { ScanNode.item($0) })
        } else {
            panel.stop()
        }
    }

    private func label(for id: String) -> Bilingual? {
        switch id {
        case Self.skipID: return succeeded ? Copy.App.continueLabel : CoreCopy.headTrySkip
        case Self.toggleID: return pointer.isOn ? Copy.Head.disable : Copy.Head.enable
        case Self.swapLeftRightID: return Copy.Head.swapLeftRight
        case Self.swapUpDownID: return Copy.Head.swapUpDown
        case Self.recenterID: return CoreCopy.headRecenter
        default: return nil
        }
    }

    private func perform(_ id: String, viaScan: Bool) {
        switch id {
        case Self.skipID:
            if !viaScan { services.feedback.select() }
            finish()
        case Self.toggleID:
            if pointer.isOn {
                services.feedback.back()
                pointer.turnOff()
            } else {
                services.feedback.enter()
                pointer.turnOn(services)
            }
        case Self.swapLeftRightID:
            if !viaScan { services.feedback.select() }
            pointer.swapLeftRight.toggle()
        case Self.swapUpDownID:
            if !viaScan { services.feedback.select() }
            pointer.swapUpDown.toggle()
        case Self.recenterID:
            if !viaScan { services.feedback.select() }
            services.hub.head.recenter()
        default:
            break
        }
    }

    private func pointed(_ direction: Direction) {
        guard !succeeded else { return }
        let choice = Vocabulary.home.choice(direction)
        chosen = direction
        succeeded = true
        services.feedback.select()
        // Yes and No are the person's words, so the voice says them. The
        // other two open more choices; here they are only proof of aim.
        if case .answer(let words) = choice.action {
            services.feedback.speak()
            services.speaker.say(words)
        }
        let language = settings.language
        announce(Copy.Head.success(choice.label)(language, settings.gender), in: language)
        reloadPanel()
        // A head-only person cannot press Continue, so the step moves on
        // by itself after a moment to enjoy it.
        finishing?.cancel()
        finishing = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func finish() {
        finishing?.cancel()
        finishing = nil
        gate?.cancel()
        panel.stop()
        pointer.turnOff()
        experience.advance(from: .headPoint)
    }
}

#Preview("Step 3 — point with your head") {
    let services = HolosServices.preview()
    HeadPointStep()
        .background(CompassTheme.background)
        .environment(Experience(start: .headPoint))
        .holos(services)
        .preferredColorScheme(.dark)
}
