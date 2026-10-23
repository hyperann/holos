import SwiftUI

/// The closing card: who Holos is for, and why it is free and open.
///
/// Two choices, scanned in turn: keep talking on the real board, or start
/// the story again. The scan waits a moment before it starts, so the press
/// that ended the replay cannot also choose here, and it keeps going while
/// the card is read, so the first press after reading chooses.
struct ClosingStep: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var scanner = Scanner()
    @State private var starting: Task<Void, Never>?

    private static let keepTalkingID = "closing.keepTalking"
    private static let startAgainID = "closing.startAgain"
    private static let nodes: [ScanNode] = [.item(ClosingStep.keepTalkingID), .item(ClosingStep.startAgainID)]

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let language = settings.language
        VStack(spacing: 18) {
            HStack {
                Spacer()
                LanguageToggle()
                    .fixedSize()
                SettingsButton()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Copy.closingTitle.text(language)
                        .font(.bedside(.largeTitle, weight: .bold))
                        .foregroundStyle(HolosTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    paragraph(Copy.closingWho, symbol: "person.2.fill", language: language)
                    paragraph(Copy.closingHow, symbol: "bubble.left.and.bubble.right.fill", language: language)
                    paragraph(Copy.closingFree, symbol: "lock.fill", language: language)
                    Copy.closingSource.text(language)
                        .font(.bedside(.footnote))
                        .foregroundStyle(BedsideTheme.softInk)
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .background(BedsideTheme.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: BedsideTheme.shadow, radius: 14, y: 6)
                .frame(maxWidth: .infinity)
            }
            .pressOnTap(isActive: isScanning)
            HStack(spacing: 16) {
                choice(Self.keepTalkingID, title: Copy.keepTalking, hint: Copy.keepTalkingHint, symbol: "bubble.left.fill", prominent: true)
                choice(Self.startAgainID, title: Copy.startAgain, hint: Copy.startAgainHint, symbol: "arrow.counterclockwise", prominent: false)
            }
            .frame(maxWidth: 760)
            .frame(height: 96)
            .switchTapArea(isActive: isScanning)
        }
        .padding(16)
        .onAppear { configure() }
        .onDisappear {
            starting?.cancel()
            scanner.stop()
        }
        .onChange(of: isScanning) {
            if isScanning { scanner.load(Self.nodes) } else { scanner.stop() }
        }
    }

    private func paragraph(_ words: Bilingual, symbol: String, language: Language) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(BedsideTheme.rust)
                .frame(width: 34)
                .accessibilityHidden(true)
            words.text(language)
                .font(.bedside(.title3))
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func choice(_ id: String, title: Bilingual, hint: Bilingual, symbol: String, prominent: Bool) -> some View {
        Button {
            services.feedback.select()
            choose(id)
        } label: {
            Label {
                title.text(settings.language)
                    .font(.bedside(.title2, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } icon: {
                Image(systemName: symbol)
            }
            .foregroundStyle(prominent ? Color.white : HolosTheme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                prominent ? BedsideTheme.personBubble(contrast) : BedsideTheme.peach,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(scanner.isHighlighted(id), cornerRadius: 22)
        .accessibilityLabel(title.text(settings.language))
        .accessibilityHint(hint.text(settings.language))
    }

    private func choose(_ id: String) {
        if id == Self.keepTalkingID {
            experience.keepTalking()
        } else if id == Self.startAgainID {
            experience.restart()
        }
    }

    private func configure() {
        let story = experience
        scanner.bind(to: services, label: { id in
            if id == Self.keepTalkingID { return Copy.keepTalking }
            if id == Self.startAgainID { return Copy.startAgain }
            return nil
        }, onSelect: { id in
            if id == Self.keepTalkingID {
                story.keepTalking()
            } else if id == Self.startAgainID {
                story.restart()
            }
        })
        scanner.listen(to: hub)
        // The card takes about half a minute to read, but the usual rest
        // after three quiet loops comes about ten seconds in here — and the
        // first press after reading would only wake the scan, choosing
        // nothing. Two choices carry no fatigue reason to rest that soon,
        // so it keeps going for about two minutes at the default speed; a
        // screen left alone still falls quiet in the end.
        scanner.loopsBeforePause = 40
        scanner.load(Self.nodes, start: false)
        let language = settings.language
        announce(Copy.closingTitle(language), in: language)
        let closingScanner = scanner
        let shouldScan = isScanning
        starting?.cancel()
        starting = Task {
            try? await Task.sleep(for: .seconds(Experience.minimumReadTime))
            guard !Task.isCancelled, shouldScan else { return }
            closingScanner.load(ClosingStep.nodes)
        }
    }
}

#Preview("Closing") {
    let experience = Experience.preview(.closing)
    return ClosingStep()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
