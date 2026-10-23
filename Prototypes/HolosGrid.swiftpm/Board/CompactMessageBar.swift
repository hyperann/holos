import SwiftUI

/// The message row's controls on a phone.
///
/// Core's `MessageBar` gives each control a fixed 88 pt: about 320 pt across
/// at rest, 404 pt with its row entered and 504 pt with Clear open — wider
/// than a phone held upright, so Speak and the Clear group's "Go back" would
/// sit partly off the edge at exactly the moment they are being scanned.
/// This strip draws the same controls from Core's own ids and actions
/// (`MessageBar.scanRow`, `perform(_:services:)`, `owns(_:)`) and shares the
/// width between them instead, so the scan, the two-press Clear and every id
/// stay exactly Core's. Only the layout is the board's.
struct CompactMessageBar: View {
    /// The id the scanner has lit, or nil when touching.
    let highlightedID: String?
    /// Puts the "Next" tag on Speak during a guided step.
    let showsNextOnSpeak: Bool

    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(MessageBuilder.self) private var message

    /// Mirrors `MessageBar`: inside the row, or inside its Clear group.
    private var rowEntered: Bool {
        highlightedID.map { MessageBar.owns($0) && $0 != MessageBar.rowID } ?? false
    }

    private var clearOpen: Bool {
        highlightedID == MessageBar.clearCancelID
            || highlightedID == MessageBar.clearConfirmID
            || highlightedID == Scanner.backID(for: MessageBar.clearID)
    }

    var body: some View {
        HStack(spacing: 6) {
            control(MessageBar.speakID, words: CoreCopy.speak, symbol: "speaker.wave.2.fill", prominent: true, hint: CoreCopy.speakHint) {
                MessageBar.speakMessage(services: services)
            }
            .guideMarker(showsNextOnSpeak)
            control(MessageBar.deleteID, words: CoreCopy.deleteLast, symbol: "delete.left.fill") {
                // `perform` knocks gently on an empty message; a real delete
                // gets the same falling "back" feel as Core's own button.
                if !message.isEmpty { services.feedback.back() }
                MessageBar.perform(MessageBar.deleteID, services: services)
            }
            if clearOpen {
                // Only ever reached by scanning: the scanner chooses these.
                control(MessageBar.clearCancelID, words: CoreCopy.clearCancel, symbol: "arrow.uturn.backward") {}
                control(MessageBar.clearConfirmID, words: CoreCopy.clearConfirm, symbol: "checkmark.circle.fill") {
                    services.feedback.back()
                    MessageBar.perform(MessageBar.clearConfirmID, services: services)
                }
            } else {
                control(MessageBar.clearID, words: CoreCopy.clear, symbol: "xmark") {
                    services.feedback.back()
                    MessageBar.perform(MessageBar.clearID, services: services)
                }
            }
            if rowEntered {
                backCell(for: clearOpen ? MessageBar.clearID : MessageBar.rowID)
            }
        }
    }

    /// One control. Widths are shared, never below 60 pt: five fit across
    /// the narrowest iPhone even with Clear open and its back cell showing.
    private func control(
        _ id: String,
        words: Bilingual,
        symbol: String,
        prominent: Bool = false,
        hint: Bilingual? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let language = settings.language
        return Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .accessibilityHidden(true)
                words.text(language)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(prominent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .frame(minWidth: 60, maxWidth: .infinity, minHeight: 60)
            .background(prominent ? HolosTheme.ink : WordKind.control.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(highlightedID == id, cornerRadius: 14)
        .accessibilityLabel(words.text(language))
        .accessibilityHint(hint.map { $0.text(language) } ?? Text(verbatim: ""))
        .accessibilityInputLabels(words.inputLabels)
        // Small labels that cannot grow with the largest text sizes, so the
        // Large Content Viewer shows them instead — as Core's bar does.
        .accessibilityShowsLargeContentViewer {
            Label {
                words.text(language)
            } icon: {
                Image(systemName: symbol)
            }
        }
    }

    /// The "go back" cell, shown only while the row (or Clear) is entered,
    /// so the person can see where the scan is.
    private func backCell(for groupID: String) -> some View {
        let id = Scanner.backID(for: groupID)
        return VStack(spacing: 3) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 20, weight: .bold))
            CoreCopy.goBack.text(settings.language)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(WordKind.control.ink)
        .padding(.horizontal, 4)
        .frame(minWidth: 60, maxWidth: .infinity, minHeight: 60)
        .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scanHighlight(highlightedID == id, cornerRadius: 14)
        // Scanning only, where the scan itself says where it is; VoiceOver
        // users (always touch) never meet it.
        .accessibilityHidden(true)
    }
}

#Preview("Compact message bar — Clear open") {
    let services = HolosServices.preview()
    services.message.add(Vocabulary.inPain)
    let experience = Experience(services: services)
    return CompactMessageBar(highlightedID: MessageBar.clearConfirmID, showsNextOnSpeak: false)
        .padding()
        .frame(width: 375)
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
