import SwiftUI

/// The message so far, with Speak, Delete last and Clear.
///
/// In this room every choice already speaks the moment it is made, so the
/// strip is a memory rather than a sentence-builder: it keeps what was said,
/// so two choices make a two-part message that Speak can say again whole.
///
/// It uses `MessageBar`'s ids, scan row and actions — including its two-step
/// Clear, so one late press can never wipe a message — but lays them out for
/// a dusk room and for a phone: on a narrow screen the controls drop below
/// the sentence instead of squeezing it to nothing.
struct MessageStrip: View {
    let isNarrow: Bool

    @Environment(Experience.self) private var experience
    @Environment(MessageBuilder.self) private var message
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let lit = experience.litID
        let rowEntered = lit.map { MessageBar.owns($0) && $0 != MessageBar.rowID } ?? false
        let clearEntered = lit == MessageBar.clearCancelID
            || lit == MessageBar.clearConfirmID
            || lit == Scanner.backID(for: MessageBar.clearID)
        Group {
            if isNarrow {
                VStack(alignment: .leading, spacing: 8) {
                    sentence
                    HStack(spacing: 8) {
                        controls(lit: lit, rowEntered: rowEntered, clearEntered: clearEntered)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    sentence
                    controls(lit: lit, rowEntered: rowEntered, clearEntered: clearEntered)
                }
            }
        }
        .padding(10)
        .background(RoomTheme.shelf(contrast), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(rowEntered ? HolosTheme.highlight : RoomTheme.outline(contrast), lineWidth: rowEntered ? 4 : 1)
        }
        .scanHighlight(lit == MessageBar.rowID, cornerRadius: 22)
    }

    private var sentence: some View {
        let language = settings.language
        let gender = settings.gender
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if message.isEmpty {
                        CoreCopy.messageEmpty.text(language)
                            .font(isNarrow ? .body : .title3)
                            .foregroundStyle(RoomTheme.quiet(contrast))
                    } else {
                        ForEach(Array(message.phrases.enumerated()), id: \.offset) { index, phrase in
                            chip(phrase, language: language, gender: gender)
                                .id(index)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            // The newest words are the ones the person is checking, so keep
            // them in view as the message grows.
            .onChange(of: message.phrases.count) {
                let last = message.phrases.count - 1
                guard last >= 0 else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                    proxy.scrollTo(last, anchor: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: isNarrow ? 46 : 64, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CoreCopy.messageLabel.text(language))
        .accessibilityValue(message.isEmpty ? CoreCopy.messageEmpty.text(language) : message.words.text(language, gender))
    }

    private func chip(_ phrase: Phrase, language: Language, gender: SpeakerGender) -> some View {
        HStack(spacing: 6) {
            Image(systemName: phrase.symbol)
                .foregroundStyle(phrase.kind.ink)
            phrase.label.text(language, gender)
                .font(.system(isNarrow ? .body : .title3, design: .rounded, weight: .semibold))
                .foregroundStyle(HolosTheme.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(phrase.kind.tint, in: Capsule())
    }

    @ViewBuilder
    private func controls(lit: String?, rowEntered: Bool, clearEntered: Bool) -> some View {
        control(
            id: MessageBar.speakID,
            symbol: "speaker.wave.2.fill",
            words: CoreCopy.speak,
            hint: CoreCopy.speakHint,
            prominent: true,
            isLit: lit == MessageBar.speakID
        )
        control(
            id: MessageBar.deleteID,
            symbol: "delete.left.fill",
            words: CoreCopy.deleteLast,
            hint: nil,
            isLit: lit == MessageBar.deleteID
        )
        // While scanning, Clear is a group: "No, keep it" is lit first, then
        // "Yes, clear all", so a late double press keeps the message. Both
        // are drawn, so the light is never on something the person cannot
        // see. A finger tap on Clear clears straight away, as in MessageBar.
        if clearEntered {
            control(
                id: MessageBar.clearCancelID,
                symbol: "arrow.uturn.backward",
                words: CoreCopy.clearCancel,
                hint: nil,
                isLit: lit == MessageBar.clearCancelID
            )
            control(
                id: MessageBar.clearConfirmID,
                symbol: "checkmark.circle.fill",
                words: CoreCopy.clearConfirm,
                hint: nil,
                isLit: lit == MessageBar.clearConfirmID
            )
        } else {
            control(
                id: MessageBar.clearID,
                symbol: "xmark",
                words: CoreCopy.clear,
                hint: nil,
                isLit: lit == MessageBar.clearID
            )
        }
        if rowEntered {
            backTile(for: clearEntered ? MessageBar.clearID : MessageBar.rowID, lit: lit)
        }
    }

    private func control(id: String, symbol: String, words: Bilingual, hint: Bilingual?, prominent: Bool = false, isLit: Bool) -> some View {
        let language = settings.language
        let width: CGFloat? = isNarrow ? nil : 86
        let maxWidth: CGFloat? = isNarrow ? .infinity : nil
        return Button {
            experience.touched(id)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: isNarrow ? 20 : 24, weight: .bold))
                words.text(language)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(prominent ? HolosTheme.ink : Color.white)
            .padding(.horizontal, 4)
            .frame(width: width)
            .frame(maxWidth: maxWidth, minHeight: isNarrow ? 52 : 64)
            // Paper, not yellow: on this board yellow only ever means "lit".
            .background(prominent ? HolosTheme.paper : RoomTheme.chip(contrast), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(isLit, cornerRadius: 16)
        // Four of these share a phone's width with a back tile, so they stop
        // growing at the first accessibility size; the Large Content Viewer
        // shows them big instead, as Core's MessageBar does.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityLabel(words.text(language))
        .accessibilityHint(hint.map { $0.text(language) } ?? Text(""))
        .accessibilityInputLabels(words.inputLabels)
        .accessibilityShowsLargeContentViewer {
            Label {
                words.text(language)
            } icon: {
                Image(systemName: symbol)
            }
        }
    }

    /// The row's "go back" cell, shown only while the scan is inside the
    /// row, so the person can see where the light is. Scanning only, so it
    /// is not a button and VoiceOver never meets it.
    private func backTile(for groupID: String, lit: String?) -> some View {
        let id = Scanner.backID(for: groupID)
        let isGuide = experience.guideID == id
        return VStack(spacing: 4) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 20, weight: .bold))
            CoreCopy.goBack.text(settings.language)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(WordKind.control.ink)
        .frame(width: 72)
        .frame(minHeight: isNarrow ? 52 : 64)
        .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .scanHighlight(lit == id, cornerRadius: 16)
        .overlay(alignment: .top) {
            if isGuide {
                GuideMarker().offset(y: -26)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Message strip") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    for id in Vocabulary.scanGoal {
        if let phrase = Vocabulary.phrase(id) {
            services.message.add(phrase)
        }
    }
    return VStack(spacing: 24) {
        MessageStrip(isNarrow: false)
        MessageStrip(isNarrow: true).frame(width: 370)
    }
    .padding()
    .background(Color(red: 0.03, green: 0.10, blue: 0.12))
    .holos(services)
    .environment(experience)
}
