import SwiftUI

/// The sentence being built, with Speak, Delete-last and Clear.
///
/// The controls have fixed ids so a board can put them in its scan
/// (`MessageBar.scanRow`) and route a selected id back through
/// `MessageBar.perform(_:services:)`. Touch users just tap them.
///
/// Clear takes two presses when scanning. The commonest scanning error is a
/// late press — the highlight moves on just before the switch lands — and
/// Clear sits right after Delete last. One late press must never wipe a
/// message that took minutes to build with a single switch, so Clear is a
/// group: the first press opens it on "No, keep it", and only "Yes, clear
/// all" — lit after a full step — clears. A double press therefore keeps the
/// message; doing nothing leaves the group by itself after two quiet loops.
struct MessageBar: View {
    /// The id the scanner has lit, if any.
    var highlightedID: String?
    /// True while the scanner is inside the bar's own row. (Also derived
    /// from `highlightedID`, so boards may leave it at its default.)
    var isRowEntered = false

    @Environment(MessageBuilder.self) private var message
    @Environment(HolosSettings.self) private var settings
    @Environment(Speaker.self) private var speaker
    @Environment(Feedback.self) private var feedback
    @Environment(\.colorSchemeContrast) private var contrast

    static let rowID = "message.row"
    static let speakID = "message.speak"
    static let deleteID = "message.delete"
    /// A group when scanning (see the type comment); a plain button to touch.
    static let clearID = "message.clear"
    static let clearCancelID = "message.clear.cancel"
    static let clearConfirmID = "message.clear.confirm"

    /// The bar's controls as one scan row, for boards that scan it.
    static var scanRow: ScanNode {
        .group(rowID, [
            .item(speakID),
            .item(deleteID),
            .group(clearID, [.item(clearCancelID), .item(clearConfirmID)]),
        ])
    }

    /// True for every id that belongs to the bar's row, including its back
    /// cells — handy for a board deciding whether the bar is in play.
    static func owns(_ id: String) -> Bool {
        [rowID, speakID, deleteID, clearID, clearCancelID, clearConfirmID,
         Scanner.backID(for: rowID), Scanner.backID(for: clearID)].contains(id)
    }

    /// Labels for auditory prompts.
    static func label(for id: String) -> Bilingual? {
        switch id {
        case rowID: CoreCopy.messageLabel
        case speakID: CoreCopy.speak
        case deleteID: CoreCopy.deleteLast
        case clearID: CoreCopy.clear
        case clearCancelID: CoreCopy.clearCancel
        case clearConfirmID: CoreCopy.clearConfirm
        default: nil
        }
    }

    /// Runs a bar control chosen by id. Returns false for ids that are not
    /// the bar's, so a board can try the bar first and fall through.
    @discardableResult
    static func perform(_ id: String, services: HolosServices) -> Bool {
        switch id {
        case speakID:
            speakMessage(services: services)
        case deleteID:
            if services.message.isEmpty {
                services.feedback.unavailable()
            } else {
                services.message.removeLast()
            }
        case clearCancelID:
            // Nothing to do: the message stays, and the selection's own
            // feedback already said the press landed.
            break
        case clearID, clearConfirmID:
            // clearID only arrives here from a tap or a board that does not
            // scan the bar's row; a scanned Clear reports clearConfirmID.
            services.message.clear()
            services.speaker.stop()
        default:
            return false
        }
        return true
    }

    /// Speaks the whole message, or knocks gently if there is nothing to say.
    static func speakMessage(services: HolosServices) {
        guard !services.message.isEmpty else {
            services.feedback.unavailable()
            return
        }
        services.feedback.speak()
        services.speaker.say(services.message.words)
    }

    private var rowEntered: Bool {
        isRowEntered || (highlightedID.map { Self.owns($0) && $0 != Self.rowID } ?? false)
    }

    private var clearEntered: Bool {
        highlightedID == Self.clearCancelID
            || highlightedID == Self.clearConfirmID
            || highlightedID == Scanner.backID(for: Self.clearID)
    }

    var body: some View {
        let language = settings.language
        HStack(spacing: 12) {
            sentence
            control(id: Self.speakID, symbol: "speaker.wave.2.fill", words: CoreCopy.speak, prominent: true) {
                guard !message.isEmpty else {
                    feedback.unavailable()
                    return
                }
                feedback.speak()
                speaker.say(message.words)
            }
            .accessibilityHint(CoreCopy.speakHint.text(language))
            control(id: Self.deleteID, symbol: "delete.left.fill", words: CoreCopy.deleteLast) {
                if message.isEmpty {
                    feedback.unavailable()
                } else {
                    feedback.back()
                    message.removeLast()
                }
            }
            if clearEntered {
                // Only ever reached by scanning; the scanner chooses these.
                control(id: Self.clearCancelID, symbol: "arrow.uturn.backward", words: CoreCopy.clearCancel) {}
                control(id: Self.clearConfirmID, symbol: "checkmark.circle.fill", words: CoreCopy.clearConfirm) {
                    feedback.back()
                    message.clear()
                    speaker.stop()
                }
            } else {
                control(id: Self.clearID, symbol: "xmark", words: CoreCopy.clear) {
                    feedback.back()
                    message.clear()
                    speaker.stop()
                }
            }
            if rowEntered {
                backControl(for: clearEntered ? Self.clearID : Self.rowID)
            }
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(rowEntered ? HolosTheme.highlight : Color.secondary.opacity(contrast == .increased ? 0.8 : 0.35), lineWidth: rowEntered ? 4 : 1.5)
        }
        .scanHighlight(highlightedID == Self.rowID, cornerRadius: 22)
    }

    private var sentence: some View {
        let language = settings.language
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if message.isEmpty {
                    CoreCopy.messageEmpty.text(language)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(message.phrases.enumerated()), id: \.offset) { _, phrase in
                        chip(phrase)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CoreCopy.messageLabel.text(language))
        .accessibilityValue(
            message.isEmpty
                ? CoreCopy.messageEmpty.text(language)
                : message.words.text(language, settings.gender)
        )
    }

    private func chip(_ phrase: Phrase) -> some View {
        HStack(spacing: 6) {
            Image(systemName: phrase.symbol)
                .foregroundStyle(phrase.kind.ink)
            phrase.label.text(settings.language, settings.gender)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(HolosTheme.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(phrase.kind.tint, in: Capsule())
    }

    private func control(
        id: String,
        symbol: String,
        words: Bilingual,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                words.text(settings.language)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(prominent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 4)
            .frame(width: 88)
            .frame(minHeight: 64)
            .background(prominent ? HolosTheme.ink : WordKind.control.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(highlightedID == id, cornerRadius: 16)
        .accessibilityLabel(words.text(settings.language))
        .accessibilityInputLabels(words.inputLabels)
        // These controls cannot grow with the largest text sizes without
        // squeezing the sentence; the Large Content Viewer shows them instead.
        .accessibilityShowsLargeContentViewer {
            Label {
                words.text(settings.language)
            } icon: {
                Image(systemName: symbol)
            }
        }
    }

    /// The row's "go back" cell, shown only while the row is entered so the
    /// person can see where the scan is.
    private func backControl(for groupID: String) -> some View {
        let id = Scanner.backID(for: groupID)
        return VStack(spacing: 4) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 22, weight: .bold))
            CoreCopy.goBack.text(settings.language)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(WordKind.control.ink)
        .frame(width: 72, height: 64)
        .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scanHighlight(highlightedID == id, cornerRadius: 16)
        .accessibilityHidden(true)
    }
}

#Preview("Message bar") {
    let services = HolosServices.preview()
    services.message.add(Phrase("pain", Bilingual("I'm in pain", uk: "Мені боляче"), says: Bilingual("I'm in pain.", uk: "Мені боляче."), symbol: "bandage.fill", kind: .urgent))
    services.message.add(Phrase("medicine", Bilingual("Medicine", uk: "Ліки"), says: Bilingual("Medicine, please.", uk: "Ліки, будь ласка."), symbol: "pills.fill", kind: .thing))
    return MessageBar(highlightedID: MessageBar.clearConfirmID)
        .padding()
        .holos(services)
}
