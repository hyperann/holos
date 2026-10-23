import SwiftUI

/// Switches, scanning, voice and language — for the person, a carer or a
/// therapist. Written in whichever language the board is in.
///
/// While it is open it holds every switch press (`SwitchHub.suspend()`):
/// presses still flash and the head meter still moves, so a carer can test
/// a switch here, but nothing reaches the board underneath — a test press
/// must never add a word or clear a message. The board's scan stands still
/// meanwhile. Screens that present it need do nothing extra.
struct SettingsSheet: View {
    @Environment(HolosSettings.self) private var settings
    @Environment(SwitchHub.self) private var hub
    @Environment(Speaker.self) private var speaker
    @Environment(Feedback.self) private var feedback
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingReset = false

    var body: some View {
        @Bindable var settings = settings
        let language = settings.language
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $settings.accessMode) {
                        CoreCopy.modeScanning.text(language).tag(AccessMode.scanning)
                        CoreCopy.modeTouch.text(language).tag(AccessMode.touch)
                    } label: {
                        CoreCopy.sectionChoosing.text(language)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    CoreCopy.sectionChoosing.text(language)
                } footer: {
                    CoreCopy.modeDetail.text(language)
                }

                Section {
                    secondsSlider(CoreCopy.scanSpeed, value: $settings.scanInterval, range: HolosSettings.scanIntervalRange, step: 0.1)
                    secondsSlider(CoreCopy.pressGap, value: $settings.pressGap, range: HolosSettings.pressGapRange, step: 0.05)
                    Toggle(isOn: $settings.auditoryPrompts) {
                        labelled(CoreCopy.auditoryPrompts, detail: CoreCopy.auditoryPromptsDetail)
                    }
                } header: {
                    CoreCopy.sectionScanning.text(language)
                } footer: {
                    CoreCopy.pressGapDetail.text(language)
                }

                Section {
                    statusRow(CoreCopy.switchTap, symbol: "hand.tap.fill", status: CoreCopy.alwaysOn)
                    statusRow(CoreCopy.switchKey, symbol: "space", status: hub.keyboardConnected ? CoreCopy.connected : CoreCopy.notConnected)
                    statusRow(
                        CoreCopy.switchController,
                        symbol: "gamecontroller.fill",
                        status: hub.controllerNames.isEmpty ? CoreCopy.notConnected : CoreCopy.connected
                    )
                    Toggle(isOn: $settings.headSwitchOn) {
                        labelled(CoreCopy.switchHead, detail: CoreCopy.switchHeadDetail)
                    }
                    if settings.headSwitchOn {
                        HeadSwitchMeter()
                        Button {
                            hub.head.recenter()
                        } label: {
                            Label {
                                CoreCopy.headRecenter.text(language)
                            } icon: {
                                Image(systemName: "scope")
                            }
                        }
                        .disabled(!hub.head.isRunning)
                        .accessibilityHint(CoreCopy.headRecenterHint.text(language))
                        degreesSlider(CoreCopy.headTurn, value: $settings.headTurnDegrees, range: HolosSettings.headTurnRange)
                        secondsSlider(CoreCopy.headHold, value: $settings.headHoldSeconds, range: HolosSettings.headHoldRange, step: 0.05)
                    }
                } header: {
                    CoreCopy.sectionSwitches.text(language)
                }

                Section {
                    Picker(selection: $settings.language) {
                        ForEach(Language.allCases) { option in
                            taggedText(option.nativeName, option).tag(option)
                        }
                    } label: {
                        CoreCopy.languageLabel.text(language)
                    }
                    Picker(selection: $settings.gender) {
                        CoreCopy.genderMasculine.text(language).tag(SpeakerGender.masculine)
                        CoreCopy.genderFeminine.text(language).tag(SpeakerGender.feminine)
                    } label: {
                        labelled(CoreCopy.speakerGender, detail: CoreCopy.speakerGenderDetail)
                    }
                    speechRateSlider(value: $settings.speechRate)
                    Label {
                        (speaker.hasUkrainianVoice ? CoreCopy.ukrainianVoiceInstalled : CoreCopy.ukrainianVoiceMissing).text(language)
                    } icon: {
                        Image(systemName: speaker.hasUkrainianVoice ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    }
                } header: {
                    CoreCopy.sectionVoice.text(language)
                }

                Section {
                    Toggle(isOn: $settings.hapticsOn) {
                        if feedback.deviceCanVibrate {
                            CoreCopy.haptics.text(language)
                        } else {
                            labelled(CoreCopy.haptics, detail: CoreCopy.hapticsUnavailable)
                        }
                    }
                    Toggle(isOn: $settings.soundOn) {
                        CoreCopy.sounds.text(language)
                    }
                } header: {
                    CoreCopy.sectionFeedback.text(language)
                }

                Section {
                    CoreCopy.privacy.text(language)
                    // A carer's mis-tap must not wipe a therapist's careful
                    // switch timing, so reset asks first.
                    Button(role: .destructive) {
                        confirmingReset = true
                    } label: {
                        CoreCopy.reset.text(language)
                    }
                    .confirmationDialog(
                        CoreCopy.resetConfirmTitle(language),
                        isPresented: $confirmingReset,
                        titleVisibility: .visible
                    ) {
                        Button(role: .destructive) {
                            settings.resetToDefaults()
                        } label: {
                            CoreCopy.reset.text(language)
                        }
                        Button(role: .cancel) {} label: {
                            CoreCopy.cancel.text(language)
                        }
                    } message: {
                        CoreCopy.resetConfirmMessage.text(language)
                    }
                } header: {
                    CoreCopy.sectionPrivacy.text(language)
                }
            }
            // The head switch drives the camera, so flipping it does more
            // than store a value.
            .onChange(of: settings.headSwitchOn) {
                if settings.headSwitchOn {
                    Task { await hub.head.enable() }
                } else {
                    hub.head.disable()
                }
            }
            .navigationTitle(CoreCopy.settingsTitle(language))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        CoreCopy.done.text(language)
                    }
                }
            }
        }
        // The board's own flash is hidden under the sheet, so the sheet
        // flashes too: a carer testing a switch here sees every press land.
        .switchPressFlash()
        .onAppear { hub.suspend() }
        .onDisappear {
            hub.resume()
            speaker.refreshVoices()
        }
    }

    private func labelled(_ title: Bilingual, detail: Bilingual) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            title.text(settings.language)
            detail.text(settings.language)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func statusRow(_ title: Bilingual, symbol: String, status: Bilingual) -> some View {
        LabeledContent {
            status.text(settings.language)
        } label: {
            Label {
                title.text(settings.language)
            } icon: {
                Image(systemName: symbol)
            }
        }
    }

    /// Numbers are formatted in the board's language ("1,4 с" in Ukrainian),
    /// and VoiceOver hears the unit as a word, not as the letter "s".
    private func secondsSlider(
        _ title: Bilingual,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        let language = settings.language
        let number = value.wrappedValue.formatted(
            .number.precision(.fractionLength(1...2)).locale(Locale(identifier: language.localeIdentifier))
        )
        return VStack(alignment: .leading) {
            LabeledContent {
                taggedText("\(number) \(CoreCopy.secondsSuffix(language))", language)
            } label: {
                title.text(language)
            }
            // The slider below says all of this once; reading it twice wastes
            // a VoiceOver user's time.
            .accessibilityHidden(true)
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(title.text(language))
                .accessibilityValue(taggedText("\(number) \(CoreCopy.secondsSpoken(language))", language))
        }
    }

    private func degreesSlider(_ title: Bilingual, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        let language = settings.language
        let degrees = Int(value.wrappedValue.rounded())
        return VStack(alignment: .leading) {
            LabeledContent {
                taggedText("\(degrees)\(CoreCopy.degreesSuffix(language))", language)
            } label: {
                title.text(language)
            }
            .accessibilityHidden(true)
            Slider(value: value, in: range, step: 1)
                .accessibilityLabel(title.text(language))
                .accessibilityValue(taggedText("\(degrees) \(CoreCopy.degreesSpoken(language))", language))
        }
    }

    /// Without an explicit value VoiceOver reads the slider's position in its
    /// range — the default 0.9 would be "50 percent", which sounds like half
    /// speed. This says "90% of normal speed".
    private func speechRateSlider(value: Binding<Double>) -> some View {
        let language = settings.language
        let percent = value.wrappedValue.formatted(
            .percent.precision(.fractionLength(0)).locale(Locale(identifier: language.localeIdentifier))
        )
        let shown = "\(percent) \(CoreCopy.ofNormalSpeed(language))"
        return VStack(alignment: .leading) {
            LabeledContent {
                taggedText(percent, language)
            } label: {
                CoreCopy.speechRate.text(language)
            }
            .accessibilityHidden(true)
            Slider(value: value, in: HolosSettings.speechRateRange, step: 0.05)
                .accessibilityLabel(CoreCopy.speechRate.text(language))
                .accessibilityValue(taggedText(shown, language))
        }
    }
}

/// Live state of the head switch: what it is doing, and how close the
/// current turn is to a press.
struct HeadSwitchMeter: View {
    @Environment(SwitchHub.self) private var hub
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let head = hub.head
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 10)
                // A black keyline under the yellow arc: yellow alone is about
                // 1.5:1 on white, and for a head-only user this arc is the only
                // sign that a turn is building towards a press.
                ZStack {
                    Circle()
                        .trim(from: 0, to: head.progress)
                        .stroke(HolosTheme.keyline, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    Circle()
                        .trim(from: 0, to: head.progress)
                        .stroke(HolosTheme.highlight, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                }
                .rotationEffect(.degrees(-90))
                Image(systemName: "face.smiling")
                    .font(.title2)
                    .rotationEffect(.radians(head.status == .tracking && !head.isCalibrating ? head.yaw * 0.6 : 0))
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)
            statusText(head).text(settings.language)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func statusText(_ head: HeadSwitch) -> Bilingual {
        if head.isCalibrating, head.status == .tracking {
            return CoreCopy.headCalibrating
        }
        switch head.status {
        case .off: return CoreCopy.headOff
        case .asking: return CoreCopy.headAsking
        case .denied: return CoreCopy.headDenied
        case .noCamera: return CoreCopy.headNoCamera
        case .searching: return CoreCopy.headSearching
        case .tracking: return CoreCopy.headTracking
        }
    }
}

#Preview("Settings") {
    SettingsSheet()
        .holos(.preview())
}
