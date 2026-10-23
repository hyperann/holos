import SwiftUI

/// The closing card: who this is for, and why it is free and open.
///
/// "Keep talking" is lit first: the board after the tour is the real app,
/// and the most natural next thing is to use it.
///
/// The card must never make anyone choose blind between "Keep talking" and
/// "Start again", which clears the message — and in scanning mode no finger
/// can scroll. So it is shown whole where it fits, with the buttons beside
/// the words on a wide screen, and only on a small one does it scroll,
/// bringing the lit buttons into view by itself.
struct ClosingStep: View {
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scanner = Scanner()
    @State private var ready = false
    @State private var gate: Task<Void, Never>?

    private static let keepTalkingID = "closing.keepTalking"
    private static let startAgainID = "closing.startAgain"
    private static let buttonsID = "closing.buttons"

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            card(buttonsBeside: false)
            card(buttonsBeside: true)
            ScrollViewReader { proxy in
                ScrollView {
                    card(buttonsBeside: false)
                }
                .onChange(of: scanner.highlightedID) { _, id in
                    if id != nil {
                        proxy.reveal(Self.buttonsID, anchor: .bottom, reduceMotion: reduceMotion)
                    }
                }
                // Once presses count, the lit button is on screen.
                .onChange(of: ready) { _, isReady in
                    if isReady, scanner.highlightedID != nil {
                        proxy.reveal(Self.buttonsID, anchor: .bottom, reduceMotion: reduceMotion)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .switchTapArea(isActive: isScanning)
        .onAppear(perform: begin)
        .onDisappear {
            gate?.cancel()
            scanner.stop()
        }
        .onChange(of: isScanning) {
            reload()
        }
    }

    // MARK: - Parts

    @ViewBuilder
    private func card(buttonsBeside: Bool) -> some View {
        if buttonsBeside {
            HStack(alignment: .bottom, spacing: 28) {
                lines
                    .frame(maxWidth: 720, alignment: .leading)
                buttons
                    .frame(width: 300)
            }
            .foregroundStyle(CompassTheme.text)
            .padding(24)
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 20) {
                lines
                buttons
                    .padding(.top, 6)
            }
            .foregroundStyle(CompassTheme.text)
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var lines: some View {
        let language = settings.language
        let gender = settings.gender
        return VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                NeedleDial(target: .north)
                    .frame(width: 64, height: 64)
                Copy.Closing.title.text(language, gender)
                    .font(CompassTheme.font(.largeTitle))
                    .accessibilityAddTraits(.isHeader)
            }
            line(Copy.Closing.who, symbol: "person.2.fill")
            line(Copy.Closing.aphasia, symbol: "text.bubble.fill")
            line(Copy.Closing.whyCompass, symbol: "square.grid.2x2.fill")
            line(Copy.Closing.free, symbol: "lock.fill")
            line(Copy.Closing.open, symbol: "book.fill")
            line(Copy.Closing.watch, symbol: "clock.fill")
        }
    }

    /// In scan order, so the screen and the light always agree.
    private var buttons: some View {
        VStack(spacing: 12) {
            StopButton(
                title: Copy.Closing.keepTalking,
                symbol: "bubble.left.and.bubble.right.fill",
                isLit: scanner.isHighlighted(Self.keepTalkingID),
                prominent: true,
                hint: Copy.Closing.keepTalkingHint
            ) {
                perform(Self.keepTalkingID, viaScan: false)
            }
            StopButton(
                title: Copy.Closing.startAgain,
                symbol: "arrow.counterclockwise",
                isLit: scanner.isHighlighted(Self.startAgainID),
                hint: Copy.Closing.startAgainHint
            ) {
                perform(Self.startAgainID, viaScan: false)
            }
        }
        .id(Self.buttonsID)
    }

    private func line(_ words: Bilingual, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(HolosTheme.highlight)
                .frame(width: 32)
                .accessibilityHidden(true)
            words.text(settings.language, settings.gender)
                .font(CompassTheme.font(.title3, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func begin() {
        scanner.bind(to: services, label: { id in
            switch id {
            case Self.keepTalkingID: return Copy.Closing.keepTalking
            case Self.startAgainID: return Copy.Closing.startAgain
            default: return nil
            }
        }, onSelect: { id in
            perform(id, viaScan: true)
        })
        // Two buttons at the end of the tour: resting would only cost the
        // judge a press to wake it, with nothing on screen to say why.
        scanner.loopsBeforePause = .max
        reload()
        hub.route { _ in
            guard ready else { return }
            scanner.press()
        }
        ready = false
        gate?.cancel()
        gate = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            ready = true
        }
        let language = settings.language
        announce(Copy.Closing.title(language), in: language)
    }

    private func reload() {
        if isScanning {
            scanner.load([.item(Self.keepTalkingID), .item(Self.startAgainID)])
        } else {
            scanner.stop()
        }
    }

    private func perform(_ id: String, viaScan: Bool) {
        if !viaScan { services.feedback.select() }
        scanner.stop()
        gate?.cancel()
        if id == Self.startAgainID {
            services.message.clear()
            experience.restart()
        } else {
            experience.keepTalking()
        }
    }
}

#Preview("Closing") {
    let services = HolosServices.preview()
    ClosingStep()
        .background(CompassTheme.background)
        .environment(Experience(start: .closing))
        .holos(services)
        .preferredColorScheme(.dark)
}
