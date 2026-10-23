import SwiftUI

/// The optional "try a head turn" moment that every judged flow offers.
///
/// It is shared so that all five prototypes treat the camera with the same
/// care: off until asked for, Skip lit first so one press moves on, and a
/// clear way out whatever the camera does. A head turn while head control is
/// on counts as success; any other press works the panel's own two buttons.
///
/// While the panel is on screen it owns switch routing. Pass the board's
/// own scanner as `pausing` and the panel stops it while shown (so two scans
/// never run at once) and hands routing back to it — restarted from the top —
/// before `onDone`. Without `pausing`, the caller must stop its scan first
/// and route presses back itself in `onDone`.
struct HeadTryPanel: View {
    /// The board's scanner, paused while the panel is shown.
    var pausing: Scanner? = nil
    let onDone: () -> Void

    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    @State private var scanner = Scanner()
    @State private var succeeded = false
    @State private var finishing: Task<Void, Never>?

    private static let skipID = "headTry.skip"
    private static let toggleID = "headTry.toggle"

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        let language = settings.language
        VStack(alignment: .leading, spacing: 18) {
            Label {
                CoreCopy.headTryTitle.text(language)
                    .font(.system(.title2, design: .rounded, weight: .bold))
            } icon: {
                Image(systemName: "face.smiling")
            }
            CoreCopy.headTryBody.text(language)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
            if settings.headSwitchOn {
                HeadSwitchMeter()
            }
            if succeeded {
                Label {
                    CoreCopy.headTrySuccess.text(language)
                        .font(.title3.bold())
                        .foregroundStyle(HolosTheme.ink)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(WordKind.action.ink)
                }
                .padding(12)
                .background(WordKind.action.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            HStack(spacing: 14) {
                panelButton(
                    id: Self.skipID,
                    title: succeeded ? CoreCopy.headTryContinue : CoreCopy.headTrySkip,
                    symbol: "chevron.right"
                ) {
                    finish()
                }
                panelButton(
                    id: Self.toggleID,
                    title: settings.headSwitchOn ? CoreCopy.headTryDisable : CoreCopy.headTryEnable,
                    symbol: settings.headSwitchOn ? "xmark.circle.fill" : "face.smiling"
                ) {
                    toggleHead()
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 640, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.5)
        }
        .switchTapArea(isActive: isScanning)
        .onAppear { start() }
        .onDisappear {
            scanner.stop()
            finishing?.cancel()
        }
        .onChange(of: isScanning) {
            if isScanning { scanner.start() } else { scanner.stop() }
        }
    }

    private func panelButton(id: String, title: Bilingual, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                title.text(settings.language)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            } icon: {
                Image(systemName: symbol)
            }
            .foregroundStyle(HolosTheme.ink)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(scanner.isHighlighted(id), cornerRadius: 16)
        .accessibilityLabel(title.text(settings.language))
        .accessibilityInputLabels(title.inputLabels)
    }

    private func start() {
        pausing?.stop()
        scanner.bind(to: services, label: { id in
            switch id {
            case Self.skipID: succeeded ? CoreCopy.headTryContinue : CoreCopy.headTrySkip
            case Self.toggleID: settings.headSwitchOn ? CoreCopy.headTryDisable : CoreCopy.headTryEnable
            default: nil
            }
        }, onSelect: { id in
            if id == Self.skipID { finish() } else if id == Self.toggleID { toggleHead() }
        })
        // Skip is lit first, so a judge who does not want the camera moves on
        // with a single press.
        scanner.load([.item(Self.skipID), .item(Self.toggleID)], start: isScanning)
        hub.route { source in
            if source == .head {
                headPressed()
            } else {
                scanner.press()
            }
        }
        announce(CoreCopy.headTryTitle(settings.language), in: settings.language)
    }

    private func toggleHead() {
        settings.headSwitchOn.toggle()
        if settings.headSwitchOn {
            services.feedback.enter()
            Task { await hub.head.enable() }
        } else {
            services.feedback.back()
            hub.head.disable()
        }
    }

    private func headPressed() {
        guard !succeeded else { return }
        succeeded = true
        services.feedback.select()
        announce(CoreCopy.headTrySuccess(settings.language), in: settings.language)
        // A moment to enjoy it, then move on by itself.
        finishing = Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func finish() {
        finishing?.cancel()
        finishing = nil
        scanner.stop()
        if let pausing {
            pausing.listen(to: hub)
            if isScanning { pausing.start() }
        } else {
            hub.unroute()
        }
        onDone()
    }
}

#Preview("Head try panel") {
    HeadTryPanel {}
        .padding()
        .holos(.preview())
}
