import SwiftUI

/// Where you are in the story, what to do now, and the controls that must
/// always stay in reach: language and Settings.
///
/// Settings and the language toggle sit outside the switch tap area on
/// purpose, so a carer can always tap them even while the whole room is one
/// switch. The words beside them are part of the switch: "press anywhere"
/// has to include the top of the screen.
struct TopBar: View {
    let isNarrow: Bool
    let openSettings: () -> Void

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Group {
            if isNarrow {
                // A phone has no height to spare, so the words get the full
                // width under the controls, the goal sentence goes (the
                // checklist says the same thing), and the hint keeps to two
                // lines.
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 10) {
                        heading
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .switchTapArea(isActive: experience.isScanning)
                        controls
                    }
                    details
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .switchTapArea(isActive: experience.isScanning)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        heading
                        details
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .switchTapArea(isActive: experience.isScanning)
                    controls
                }
            }
        }
        // Chrome stops growing at the first accessibility size, so the room
        // keeps its place on screen; the cards and phrase cells carry the
        // largest text.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .animation(.easeInOut(duration: 0.2), value: experience.hint)
    }

    /// Which part of the story this is, and its title.
    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let index = experience.partIndex {
                PartDots(current: index)
            }
            experience.title.text(settings.language, settings.gender)
                .font(.system(isNarrow ? .title3 : .title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.white)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// The goal, how to reach it, and what to press next.
    private var details: some View {
        let language = settings.language
        let gender = settings.gender
        return VStack(alignment: .leading, spacing: 6) {
            if let goal = experience.goal {
                if !isNarrow {
                    goal.text(language, gender)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(HolosTheme.highlight)
                }
                TargetChecklist()
            }
            if let how = experience.how, !isNarrow || experience.boardMode == .free {
                how.text(language, gender)
                    .font(isNarrow ? .subheadline : .body)
                    .foregroundStyle(RoomTheme.quiet(contrast))
                    .lineLimit(isNarrow ? 2 : nil)
                    .minimumScaleFactor(isNarrow ? 0.8 : 1)
            }
            if let hint = experience.hint {
                Label {
                    hint.text(language, gender)
                        .lineLimit(isNarrow ? 2 : nil)
                        .minimumScaleFactor(isNarrow ? 0.8 : 1)
                } icon: {
                    Image(systemName: "hand.point.up.left.fill")
                        .foregroundStyle(HolosTheme.highlight)
                }
                .font(.system(isNarrow ? .subheadline : .body, design: .rounded, weight: .bold))
                .foregroundStyle(Color.white)
            }
            if let help = experience.helpText {
                Label {
                    help.text(language, gender)
                        .lineLimit(isNarrow ? 2 : nil)
                        .minimumScaleFactor(isNarrow ? 0.8 : 1)
                } icon: {
                    Image(systemName: "questionmark.circle.fill")
                }
                .font(.system(isNarrow ? .subheadline : .body, design: .rounded, weight: .semibold))
                .foregroundStyle(HolosTheme.highlight)
            }
        }
    }

    private var controls: some View {
        HStack(alignment: .top, spacing: isNarrow ? 10 : 12) {
            LanguageToggle()
            Button(action: openSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 50, height: 50)
                    .background(RoomTheme.chip(contrast), in: Circle())
                    .overlay { Circle().strokeBorder(RoomTheme.outline(contrast), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(CoreCopy.settingsButton.text(settings.language))
            .accessibilityHint(CoreCopy.settingsButtonHint.text(settings.language))
            .accessibilityInputLabels(CoreCopy.settingsButton.inputLabels)
        }
    }
}

/// Four short bars: which of the four judged parts this is.
struct PartDots: View {
    let current: Int

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = settings.language
        let names = Copy.partNames
        HStack(spacing: 6) {
            ForEach(names.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? HolosTheme.highlight : Color.white.opacity(0.25))
                    .frame(width: index == current ? 28 : 14, height: 6)
            }
            if names.indices.contains(current) {
                names[current].text(language)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .padding(.leading, 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.partLabel(current + 1, of: names.count).text(language))
    }
}

/// The goal's phrases, each ticked off as it is said.
struct TargetChecklist: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        HStack(spacing: 8) {
            ForEach(experience.targets, id: \.self) { id in
                if let phrase = Vocabulary.phrase(id) {
                    let done = experience.doneTargets.contains(id)
                    Label {
                        phrase.label.text(language, gender)
                    } icon: {
                        Image(systemName: done ? "checkmark.circle.fill" : phrase.symbol)
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(done ? HolosTheme.ink : Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(done ? WordKind.action.tint : Color.white.opacity(0.12), in: Capsule())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(phrase.label.text(language, gender))
                    .accessibilityAddTraits(done ? .isSelected : [])
                }
            }
        }
    }
}

#Preview("Top bar") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return TopBar(isNarrow: false) {}
        .padding()
        .background(Color(red: 0.03, green: 0.10, blue: 0.12))
        .holos(services)
        .environment(experience)
        .onAppear { experience.go(to: .scanRoom) }
}
