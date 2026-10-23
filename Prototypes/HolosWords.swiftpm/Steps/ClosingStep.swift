import SwiftUI

/// The closing screen, about 30 seconds: who this is for, and why it is
/// free, private and open source. Then the choice the real app starts
/// with — keep talking on the full board, or watch the tour again.
struct ClosingStep: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var scanner = Scanner()
    @State private var settle: Task<Void, Never>?

    private static let keepID = "closing.keep"
    private static let againID = "closing.again"

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let language = settings.language
        // Read here, in this view's own body, so changes always redraw it.
        let keepLit = scanner.isHighlighted(Self.keepID)
        let againLit = scanner.isHighlighted(Self.againID)
        NarrativePage(isScanning: isScanning) {
            Copy.closingTitle.text(language)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Copy.closingWho.text(language)
                .font(.title3)
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Copy.closingPeople.text(language)
                .font(.title3)
                .foregroundStyle(WordsTheme.secondary(contrast))
                .fixedSize(horizontal: false, vertical: true)
            Copy.closingWhy.text(language)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        } actions: {
            HStack(spacing: 12) {
                BigButton(
                    title: Copy.keepTalking,
                    symbol: "text.bubble.fill",
                    prominent: true,
                    isHighlighted: keepLit,
                    hint: Copy.keepTalkingHint
                ) {
                    services.feedback.select()
                    keepTalking()
                }
                BigButton(
                    title: Copy.startAgain,
                    symbol: "arrow.counterclockwise",
                    isHighlighted: againLit,
                    hint: Copy.startAgainHint
                ) {
                    services.feedback.select()
                    startAgain()
                }
            }
        }
        .onAppear { start() }
        .onDisappear {
            scanner.stop()
            settle?.cancel()
        }
        .onChange(of: isScanning) {
            if isScanning { scanner.start() } else { scanner.stop() }
        }
    }

    private func start() {
        scanner.bind(to: services, label: { id in
            switch id {
            case Self.keepID: Copy.keepTalking
            case Self.againID: Copy.startAgain
            default: nil
            }
        }, onSelect: { id in
            if id == Self.keepID {
                keepTalking()
            } else if id == Self.againID {
                startAgain()
            }
        })
        // A two-button reading screen: the next step must always be one
        // press away. About 110 words take longer than three quiet loops,
        // and a judge should never find the first press only wakes the scan.
        scanner.loopsBeforePause = .max
        scanner.load([.item(Self.keepID), .item(Self.againID)], start: false)
        scanner.listen(to: hub)
        announce(Copy.closingTitle(settings.language), in: settings.language)
        settle?.cancel()
        settle = Task {
            // A beat to land, so the press that ended step 4 cannot also
            // choose here.
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            if isScanning { scanner.start() }
        }
    }

    private func keepTalking() {
        guard experience.step == .closing else { return }
        scanner.stop()
        experience.keepTalking()
    }

    private func startAgain() {
        guard experience.step == .closing else { return }
        scanner.stop()
        experience.restart()
    }
}

#Preview("Closing") {
    let experience = Experience()
    experience.show(.closing)
    return ClosingStep()
        .environment(experience)
        .holos(.preview())
}
