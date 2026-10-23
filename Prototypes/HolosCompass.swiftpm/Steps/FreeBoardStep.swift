import SwiftUI

/// The board on its own, after the tour — which is to say, the real app.
///
/// Everything works here as it would at a bedside: the scan over the whole
/// tree, touch, the language stop at home, Clear, and head pointing for
/// someone who can only move their head. The row of controls above the
/// board is for a carer's hands; the person's own switch never needs it.
struct FreeBoardStep: View {
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    @State private var controller = CompassController()

    private var pointer: HeadPointer { experience.pointer }

    private var isScanning: Bool {
        settings.effectiveMode(voiceOver: voiceOver, switchControl: switchControl) == .scanning
    }

    var body: some View {
        VStack(spacing: 12) {
            VoiceNotice()
            carerControls
            if pointer.isOn {
                PointingStatus(
                    pointer: pointer,
                    // Below home the head can step back on its own, so a
                    // head-only person is never stuck deep in the tree.
                    pressHint: controller.isHome ? Copy.Head.pressSpeak : Copy.Head.restBack
                )
                .padding(12)
                .background(CompassTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            CompassDial(controller: controller, pointer: pointer)
                // The tap area stays on while the head points: then a tap
                // is the person's one other movement (Back, or Speak).
                .switchTapArea(isActive: isScanning)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .onAppear(perform: begin)
        .onDisappear {
            controller.stop()
            pointer.turnOff()
        }
        .onChange(of: isScanning) { _, scanning in
            controller.setScanning(scanning)
        }
        .onChange(of: pointer.isPointing) {
            // Face found or lost: hand the board between head and scan.
            controller.reloadScan()
        }
    }

    /// Touch-only controls, outside the switch area on purpose: turning the
    /// camera on is a decision for the person with a carer, not something a
    /// stray scan press should do.
    private var carerControls: some View {
        let language = settings.language
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                pointingToggle(language)
                if pointer.isOn {
                    swapButtons(language)
                }
                Spacer(minLength: 0)
                startAgain(language)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    pointingToggle(language)
                    startAgain(language)
                }
                if pointer.isOn {
                    HStack(spacing: 10) {
                        swapButtons(language)
                    }
                }
            }
        }
    }

    private func pointingToggle(_ language: Language) -> some View {
        smallButton(
            pointer.isOn ? Copy.Head.disable : Copy.Board.headPointing,
            symbol: pointer.isOn ? "xmark.circle.fill" : "face.smiling",
            hint: Copy.Board.headPointingHint,
            language: language
        ) {
            if pointer.isOn {
                services.feedback.back()
                pointer.turnOff()
            } else {
                services.feedback.enter()
                pointer.turnOn(services)
            }
        }
    }

    @ViewBuilder
    private func swapButtons(_ language: Language) -> some View {
        smallButton(Copy.Head.swapLeftRight, symbol: "arrow.left.arrow.right", hint: Copy.Head.swapHint, language: language) {
            services.feedback.select()
            pointer.swapLeftRight.toggle()
        }
        smallButton(Copy.Head.swapUpDown, symbol: "arrow.up.arrow.down", hint: Copy.Head.swapHint, language: language) {
            services.feedback.select()
            pointer.swapUpDown.toggle()
        }
    }

    private func startAgain(_ language: Language) -> some View {
        smallButton(Copy.Closing.startAgain, symbol: "arrow.counterclockwise", hint: Copy.Closing.startAgainHint, language: language) {
            services.feedback.select()
            controller.stop()
            services.message.clear()
            experience.restart()
        }
    }

    private func smallButton(
        _ title: Bilingual,
        symbol: String,
        hint: Bilingual,
        language: Language,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                title.text(language, settings.gender)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } icon: {
                Image(systemName: symbol)
            }
            .font(CompassTheme.font(.subheadline, weight: .bold))
            .foregroundStyle(CompassTheme.text)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(CompassTheme.surfaceRaised, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title.text(language, settings.gender))
        .accessibilityHint(hint.text(language))
        .accessibilityInputLabels(title.inputLabels)
    }

    private func begin() {
        controller.attach(services: services, pointer: pointer)
        controller.onEvent = nil
        controller.goHome()
        controller.start(scanning: isScanning)
        hub.route { source in
            controller.press(source)
        }
        let language = settings.language
        announce(Copy.Steps.free(language), in: language)
    }
}

#Preview("Free board") {
    let services = HolosServices.preview()
    FreeBoardStep()
        .background(CompassTheme.background)
        .environment(Experience(start: .free))
        .holos(services)
        .preferredColorScheme(.dark)
}
