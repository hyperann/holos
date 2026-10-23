import SwiftUI

/// Holos Grid's look: a calm clinical sheet — off-white paper, deep navy
/// ink, white cards — so the only colour on screen is the Fitzgerald tint
/// that carries meaning, and the only bright thing is the yellow scan ring.
enum GridTheme {
    static let paper = Color(red: 0.965, green: 0.969, blue: 0.976)
    static let navy = Color(red: 0.08, green: 0.17, blue: 0.36)
    static let card = Color.white
    static let line = Color(red: 0.78, green: 0.81, blue: 0.86)
    /// For lines that matter but should sit back: step line, tips, the
    /// English gloss. About 8:1 on white and 7.6:1 on the pale people tint,
    /// where the system's `.secondary` grey manages only about 3.4:1 — too
    /// faint for 13–17 pt text read from a hospital bed.
    static let quietInk = HolosTheme.ink.opacity(0.75)

    static func rounded(_ style: Font.TextStyle, _ weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

extension View {
    /// A white card with a hairline edge (a firm one under Increase Contrast).
    func gridCard(padding: CGFloat = 20) -> some View {
        modifier(GridCardModifier(padding: padding))
    }

    /// Makes a narrative screen, or its scrolling text, answer to the switch.
    ///
    /// An ordinary tap anywhere, in scanning and touch mode alike — not Core's
    /// touch-down layer, which would sit over the text and stop it scrolling.
    /// On a phone, or at large text sizes, the end of a card can be below the
    /// fold, and a drag must still reach it. Here a press only ever means
    /// "continue", so nothing is lost by waiting for the finger to lift; keys,
    /// controllers and the head switch are unaffected. VoiceOver and Switch
    /// Control get nothing extra: they use the visible Continue button.
    func narrativeTapArea(isActive: Bool = true) -> some View {
        modifier(NarrativeTapModifier(isActive: isActive))
    }
}

private struct GridCardModifier: ViewModifier {
    let padding: CGFloat
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(GridTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(contrast == .increased ? GridTheme.navy : GridTheme.line, lineWidth: contrast == .increased ? 2.5 : 1.5)
            }
    }
}

private struct NarrativeTapModifier: ViewModifier {
    let isActive: Bool
    @Environment(SwitchHub.self) private var hub
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    @ViewBuilder
    func body(content: Content) -> some View {
        if !isActive || voiceOver || switchControl {
            content
        } else {
            content
                .contentShape(Rectangle())
                .onTapGesture { hub.press(.tap) }
        }
    }
}

/// The one "continue" control on a narrative card, permanently lit: a lit
/// thing is what a press picks, and here a press always continues.
struct ContinueButton: View {
    var title: Bilingual = Copy.pressToContinue

    @Environment(Experience.self) private var experience
    @Environment(SwitchHub.self) private var hub

    var body: some View {
        let language = experience.language
        Button {
            hub.press(.tap)
        } label: {
            HStack(spacing: 10) {
                title.text(language)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .font(GridTheme.rounded(.title3))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 28)
            .frame(minHeight: 60)
            .background(GridTheme.navy, in: Capsule())
        }
        .buttonStyle(.plain)
        .scanHighlight(true, cornerRadius: 30)
        .accessibilityLabel(title.text(language))
        .accessibilityHint(Copy.continueHint.text(language))
        .accessibilityInputLabels(title.inputLabels)
    }
}

/// A dimmed backdrop and a centred card that scrolls when the screen is
/// too small for it.
struct OverlayCard<Content: View>: View {
    /// An id inside the content whose bottom edge is scrolled into view as
    /// the card appears. For a card whose choices sit under a touch-down tap
    /// area — which cannot be scrolled — so they start on screen.
    private let bottomID: String?
    private let content: () -> Content
    @Environment(\.colorSchemeContrast) private var contrast

    init(scrollingTo bottomID: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.bottomID = bottomID
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(contrast == .increased ? 0.5 : 0.28)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                ScrollViewReader { reader in
                    ScrollView {
                        content()
                            .frame(maxWidth: 680)
                            .padding(20)
                            .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onAppear {
                        guard let bottomID else { return }
                        reader.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }
}

#Preview("Theme") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    return ZStack {
        GridTheme.paper.ignoresSafeArea()
        OverlayCard {
            VStack(alignment: .leading, spacing: 16) {
                Copy.oneSwitchTitle.text(.english)
                    .font(GridTheme.rounded(.title))
                Copy.oneSwitchHowScanning.text(.english)
                ContinueButton()
            }
            .gridCard()
        }
    }
    .environment(experience)
    .holos(services)
}
