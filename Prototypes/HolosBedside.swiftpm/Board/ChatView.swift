import SwiftUI

/// The conversation so far, newest at the bottom.
///
/// The transcript is the record of the person being heard, so it stays on
/// screen the whole time and scrolls itself to each new line. It is one
/// VoiceOver-readable list in the order things were said.
struct ChatView: View {
    /// The line being re-spoken in step 4, if any.
    var replayingID: Int?
    /// The language the lines are drawn in, when it is not the board's own
    /// (step 4 shows them in Ukrainian; see `ChatBubble.language`).
    var language: Language? = nil

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The typing dots' id; real lines count up from zero.
    private static let typingID = -1

    var body: some View {
        let conversation = experience.conversation
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(conversation.lines) { line in
                        ChatBubble(line: line, isReplaying: line.id == replayingID, language: language)
                            .id(line.id)
                            .transition(
                                reduceMotion
                                    ? AnyTransition.opacity
                                    : AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity)
                            )
                    }
                    if conversation.isTyping {
                        TypingBubble()
                            .id(Self.typingID)
                            .transition(.opacity)
                    }
                }
                .padding(16)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: conversation.lines.count)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: conversation.isTyping)
            }
            // It follows the conversation by itself, and it can always be
            // scrolled back by hand too: in scanning mode the screen makes it
            // a clean-tap switch (`pressOnTap`), so a tap still presses and a
            // drag scrolls. The answers beside it keep Core's touch-down
            // switch, the one a shaking hand needs most.
            .scrollIndicators(.visible)
            .onAppear { scrollToEnd(proxy) }
            .onChange(of: conversation.lines.count) { scrollToEnd(proxy) }
            .onChange(of: conversation.isTyping) { scrollToEnd(proxy) }
            .onChange(of: replayingID) {
                guard let replayingID else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    proxy.scrollTo(replayingID, anchor: .center)
                }
            }
        }
        .background(BedsideTheme.chatBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Copy.transcriptLabel.text(settings.language))
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        let conversation = experience.conversation
        let target = conversation.isTyping ? Self.typingID : conversation.lines.last?.id
        guard let target else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }
}

#Preview("Chat") {
    let experience = Experience.preview()
    return ChatView()
        .padding()
        .environment(experience)
        .holos(experience.services)
}
