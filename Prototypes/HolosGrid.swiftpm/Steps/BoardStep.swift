import SwiftUI

/// Steps 2, 3 and 4 and the free board: the same grid every time, with a
/// different card above or over it.
///
/// Keeping one board across all of them is the point of this prototype —
/// the judge learns one layout in step 2 and simply keeps using it.
struct BoardStep: View {
    @Environment(Experience.self) private var experience
    @Environment(Speaker.self) private var speaker

    /// So the overlay can scroll the panel's two buttons into view.
    private static let headTryID = "grid.headTry"

    private enum Overlay: Equatable {
        case nothing
        case intro
        case success
        case headTry
        case ukrainian
    }

    private var overlay: Overlay {
        switch experience.step {
        case .oneSwitch, .aphasia:
            switch experience.phase {
            case .intro: return .intro
            case .working: return .nothing
            case .done: return .success
            case .headTry: return .headTry
            }
        case .ukrainian:
            return .ukrainian
        case .problem, .closing, .free:
            return .nothing
        }
    }

    /// The board takes presses only while it is the thing being used.
    private var boardIsLive: Bool {
        experience.step == .free || (experience.step.isGuided && experience.phase == .working)
    }

    var body: some View {
        let current = overlay
        ZStack {
            VStack(spacing: 10) {
                if experience.step != .ukrainian {
                    VoiceNotice()
                }
                header
                GridBoardView(
                    board: experience.board,
                    isScanning: experience.modeIsScanning,
                    showsGuide: experience.step.isGuided
                        && (experience.phase == .intro || experience.phase == .working)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .switchTapArea(isActive: experience.modeIsScanning && boardIsLive)
            .accessibilityHidden(current != .nothing)

            if current != .nothing {
                overlayCard(current)
                    .transition(.opacity)
            }
        }
        // Fades only: no movement, so nothing to change for Reduce Motion.
        .animation(.easeInOut(duration: 0.25), value: current)
        .onChange(of: speaker.currentText) { _, text in
            if let text {
                experience.board.speechStarted(text)
            } else {
                experience.board.speechEnded()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if experience.step.isGuided {
            GoalCard()
        } else if experience.step == .free {
            FreeHeader()
        }
    }

    @ViewBuilder
    private func overlayCard(_ kind: Overlay) -> some View {
        switch kind {
        case .nothing:
            EmptyView()
        case .intro:
            OverlayCard {
                IntroCard()
            }
            .narrativeTapArea()
        case .success:
            OverlayCard {
                SuccessCard()
            }
            .narrativeTapArea()
        case .headTry:
            // On its own, after step 3's success card has had its own read
            // gate: shown together, the panel took the switch at once and a
            // quick second press skipped both.
            OverlayCard(scrollingTo: Self.headTryID) {
                // Core's panel borrows the switch while it is shown;
                // `headTryFinished` takes it back for the tour.
                HeadTryPanel {
                    experience.headTryFinished()
                }
                .id(Self.headTryID)
            }
            // Touches outside the panel are presses too, which the panel
            // (owning the switch just now) turns into its own choices.
            .switchTapArea(isActive: experience.modeIsScanning)
        case .ukrainian:
            OverlayCard {
                UkrainianCard()
            }
            .narrativeTapArea()
        }
    }
}

/// The free board's one-line header.
private struct FreeHeader: View {
    @Environment(Experience.self) private var experience

    var body: some View {
        let language = experience.language
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Copy.freeTitle.text(language)
                .font(GridTheme.rounded(.title2))
                .foregroundStyle(GridTheme.navy)
                .accessibilityAddTraits(.isHeader)
            Copy.freeBody.text(language)
                .font(.subheadline)
                .foregroundStyle(GridTheme.quietInk)
                .lineLimit(2)
            Spacer(minLength: 0)
            if experience.board.scanner.state == .paused {
                Copy.scanPaused.text(language)
                    .font(.subheadline.bold())
                    .foregroundStyle(GridTheme.navy)
                    .lineLimit(2)
            }
        }
        .padding(.top, 4)
    }
}

#Preview("Step 2 — working") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.oneSwitch)
    return BoardStep()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}

#Preview("Step 3 — done") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.aphasia, phase: .done)
    return BoardStep()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}

#Preview("Step 3 — head turn") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.aphasia, phase: .headTry)
    return BoardStep()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
