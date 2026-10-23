import SwiftUI

/// Row sizes for the space the board is given.
///
/// The fixed rows (message, quick phrases, topics) keep a steady size so
/// they are always where the hand and eye expect them; the two topic rows
/// take whatever is left, up to a comfortable maximum. On a phone, or with
/// very large text, the rows keep a minimum size and the board scrolls —
/// following the scan by itself, because a switch user cannot scroll.
///
/// These are a prediction from fixed heights. `GridBoardView` also measures
/// what was actually laid out, because text can still grow past them.
struct BoardMetrics {
    let compact: Bool
    let gutter: CGFloat
    let cellGap: CGFloat
    let messageHeight: CGFloat
    let quickHeight: CGFloat
    let topicsLines: Int
    let topicsLineHeight: CGFloat
    let headerHeight: CGFloat
    let backWidth: CGFloat
    let cellRowHeight: CGFloat
    let needsScroll: Bool

    var topicsHeight: CGFloat {
        CGFloat(topicsLines) * topicsLineHeight + CGFloat(max(topicsLines - 1, 0)) * cellGap
    }

    init(size: CGSize) {
        let compact = size.width < 640
        // Budgeted so the whole board fits an 11-inch iPad in landscape
        // (834 pt) beside the goal card, with topic cells over 100 pt tall.
        let gutter: CGFloat = compact ? 6 : 8
        let cellGap: CGFloat = compact ? 6 : 12
        // Core's message bar is 84 pt. A narrow screen has the board's own
        // row instead: the 44 pt sentence strip over 60 pt compact controls,
        // inside the same ring padding as every other scanned row.
        let messageHeight: CGFloat = compact ? 44 + 6 + 60 + BoardIDs.rowPadding * 2 : 84
        let quickHeight: CGFloat = compact ? 76 : 88
        let topicsLines = compact ? 2 : 1
        let topicsLineHeight: CGFloat = compact ? 46 : 56
        let headerHeight: CGFloat = compact ? 28 : 30
        let chrome = BoardIDs.rowPadding * 2
        let topicsHeight = CGFloat(topicsLines) * topicsLineHeight + CGFloat(topicsLines - 1) * cellGap
        let scannedRows: CGFloat = quickHeight + topicsHeight + 2 * chrome
        let spacing: CGFloat = 5 * gutter + 8
        let fixed: CGFloat = messageHeight + scannedRows + headerHeight + spacing
        let available = (size.height - fixed) / 2 - chrome
        let minimum: CGFloat = compact ? 84 : 100

        self.compact = compact
        self.gutter = gutter
        self.cellGap = cellGap
        self.messageHeight = messageHeight
        self.quickHeight = quickHeight
        self.topicsLines = topicsLines
        self.topicsLineHeight = topicsLineHeight
        self.headerHeight = headerHeight
        backWidth = compact ? 56 : 100
        needsScroll = available < minimum
        cellRowHeight = min(max(available, minimum), 240)
    }
}

/// The whole grid, top to bottom in scan order.
struct GridBoardView: View {
    let board: GridBoard
    let isScanning: Bool
    /// Show the "Next" tag (guided steps only).
    let showsGuide: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The laid-out height of all the rows, measured — see `body`.
    @State private var contentHeight: CGFloat = 0

    /// A few points over is not an overflow: Core's message bar can come out
    /// a point or two taller than its budget (a Ukrainian label wrapping in
    /// its 64 pt controls), which draws harmlessly into the padding under the
    /// board. Treating that as scrolling would clip the board, cutting the
    /// sides off the lit message bar's lifted ring.
    private static let overflowTolerance: CGFloat = 8

    /// The row the scan is in, or on — what must stay on screen.
    private var focusRowID: String? {
        if let entered = board.scanner.path.first { return entered }
        return board.scanner.highlightedID
    }

    var body: some View {
        let target = showsGuide ? board.guideTarget : nil
        GeometryReader { proxy in
            let metrics = BoardMetrics(size: proxy.size)
            // Measured, not only predicted: at large text sizes the message
            // bar grows past the fixed budget, and a board that overflows
            // without knowing it would leave a lit bottom row off screen.
            let scrolls = metrics.needsScroll || contentHeight > proxy.size.height + Self.overflowTolerance
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing: metrics.gutter) {
                        MessageRow(board: board, isScanning: isScanning, metrics: metrics, target: target)
                            .id(MessageBar.rowID)
                        QuickRow(board: board, isScanning: isScanning, metrics: metrics)
                            .id(BoardIDs.quickRow)
                        TopicsRow(board: board, isScanning: isScanning, metrics: metrics, target: target)
                            .id(BoardIDs.topicsRow)
                        TopicHeader(board: board, metrics: metrics)
                        PhraseRow(
                            rowID: BoardIDs.topicRowOne, number: 1, phrases: board.firstRow,
                            board: board, isScanning: isScanning, metrics: metrics, target: target
                        )
                        .id(BoardIDs.topicRowOne)
                        PhraseRow(
                            rowID: BoardIDs.topicRowTwo, number: 2, phrases: board.secondRow,
                            board: board, isScanning: isScanning, metrics: metrics, target: target
                        )
                        .id(BoardIDs.topicRowTwo)
                    }
                    .padding(.vertical, 4)
                    // Read with `onChange` rather than a PreferenceKey: with
                    // Xcode 16's SDK `onPreferenceChange` takes a Sendable
                    // closure, which cannot set this view's state in Swift 6.
                    .background {
                        GeometryReader { rows in
                            Color.clear
                                .onAppear { contentHeight = rows.size.height }
                                .onChange(of: rows.size.height) { _, height in
                                    contentHeight = height
                                }
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                // When everything fits, let the lit message bar's lift and
                // the "Next" tags draw past the edge instead of being cut.
                .scrollClipDisabled(!scrolls)
                .onChange(of: focusRowID) { _, id in
                    guard scrolls, let id else { return }
                    if reduceMotion {
                        reader.scrollTo(id, anchor: .center)
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            reader.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        // The cells have fixed sizes so the grid never moves; past this size
        // their text would only shrink to fit. Each control also offers the
        // Large Content Viewer for anyone who needs it bigger still.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

#Preview("Board — iPad", traits: .landscapeLeft) {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.oneSwitch)
    return GridBoardView(board: experience.board, isScanning: true, showsGuide: true)
        .padding()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}

#Preview("Board — touch") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    experience.showForPreview(.free)
    return GridBoardView(board: experience.board, isScanning: false, showsGuide: false)
        .padding()
        .background(GridTheme.paper)
        .environment(experience)
        .holos(services)
}
