import SwiftUI

/// The gear in the corner of every screen.
///
/// It always sits outside the tap-anywhere switch area, so a carer can
/// reach Settings with an ordinary tap even while the board is scanning.
struct SettingsButton: View {
    @Environment(HolosServices.self) private var services
    @Environment(HolosSettings.self) private var settings
    @Environment(Feedback.self) private var feedback
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var isPresented = false

    var body: some View {
        Button {
            feedback.enter()
            isPresented = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(HolosTheme.ink)
                .frame(width: 52, height: 52)
                .background(BedsideTheme.card, in: Circle())
                .overlay { Circle().strokeBorder(BedsideTheme.line(contrast), lineWidth: 1.5) }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(CoreCopy.settingsButton.spoken(settings.language)))
        .accessibilityHint(CoreCopy.settingsButtonHint.text(settings.language))
        .sheet(isPresented: $isPresented) {
            SettingsSheet()
                .holos(services)
        }
    }
}

/// The strip along the top of a screen: its own content on the left, the
/// language toggle and the gear on the right.
///
/// On a narrow screen the two controls move above the content instead of
/// squeezing it into a column a few words wide.
struct TopBar<Content: View>: View {
    private let languageLit: Bool
    private let content: Content

    @Environment(\.horizontalSizeClass) private var sizeClass

    init(languageLit: Bool = false, @ViewBuilder content: () -> Content) {
        self.languageLit = languageLit
        self.content = content()
    }

    var body: some View {
        if sizeClass == .compact {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Spacer(minLength: 0)
                    controls
                }
                content
            }
        } else {
            HStack(alignment: .top, spacing: 14) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                controls
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            LanguageToggle(isHighlighted: languageLit)
                .fixedSize()
            SettingsButton()
        }
    }
}

/// The small step label, a headline and an optional line of explanation.
struct StepHeader: View {
    let step: Bilingual
    let title: Bilingual
    var detail: Bilingual?

    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let language = settings.language
        VStack(alignment: .leading, spacing: 6) {
            step.text(language)
                .font(.bedside(.subheadline, weight: .heavy))
                .foregroundStyle(BedsideTheme.rust)
            title.text(language)
                .font(.bedside(.title2, weight: .bold))
                .foregroundStyle(HolosTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let detail {
                detail.text(language)
                    .font(.bedside(.body))
                    .foregroundStyle(BedsideTheme.softInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The chat beside the board on a wide screen, above it on a tall one.
///
/// iPad landscape is the main canvas; iPad portrait and iPhone portrait
/// stack the two so neither is squeezed into a sliver.
struct SplitLayout<Chat: View, Board: View>: View {
    private let chatShare: CGFloat
    private let chat: Chat
    private let board: Board

    /// - Parameter chatShare: The part of the height the chat takes when
    ///   the two are stacked. A phone gives the answers more, because the
    ///   cells must stay big enough to hit, and the chat scrolls itself to
    ///   the newest line anyway.
    init(chatShare: CGFloat = 0.34, @ViewBuilder chat: () -> Chat, @ViewBuilder board: () -> Board) {
        self.chatShare = chatShare
        self.chat = chat()
        self.board = board()
    }

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height * 1.05 {
                HStack(spacing: 16) {
                    chat
                        .frame(width: geometry.size.width * 0.38)
                    board
                }
            } else {
                VStack(spacing: 12) {
                    chat
                        .frame(height: geometry.size.height * chatShare)
                    board
                }
            }
        }
    }
}

extension View {
    /// Makes a long text that must stay scrollable a switch too: a clean
    /// tap presses, a drag still scrolls.
    ///
    /// Core's `switchTapArea` presses on touch-DOWN, which is right for a
    /// shaking hand but would turn every scroll into a press. So this is used
    /// only where reading needs scrolling — the transcript, the closing card,
    /// a card too tall for a small screen — always beside a big touch-down
    /// switch area that stays the main target. Off in touch mode, where a
    /// tap must stay an ordinary tap.
    func pressOnTap(isActive: Bool) -> some View {
        modifier(PressOnTapModifier(isActive: isActive))
    }
}

private struct PressOnTapModifier: ViewModifier {
    let isActive: Bool
    @Environment(SwitchHub.self) private var hub

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                TapGesture().onEnded { hub.press(.tap) },
                including: isActive ? .all : .subviews
            )
    }
}

#Preview("Chrome") {
    let experience = Experience.preview()
    return VStack(spacing: 24) {
        HStack {
            StepHeader(step: Copy.step2, title: Copy.goalPain, detail: Copy.goalPainDetail)
            SettingsButton()
        }
        SplitLayout {
            Color.orange.opacity(0.2)
        } board: {
            Color.blue.opacity(0.2)
        }
    }
    .padding()
    .environment(experience)
    .holos(experience.services)
}
