import SwiftUI

/// Row sizes for the space the board is given.
///
/// The fixed rows (message, quick phrases, topics) keep a steady size so
/// they are always where the hand and eye expect them; the two topic rows
/// take whatever is left, up to a comfortable maximum. When the rows would
/// fall below their minimum — under the goal banner on an iPad, on a phone,
/// or with very large text — they keep it and the board scrolls, following
/// the scan by itself, because a switch user cannot scroll.
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
        let gutter: CGFloat = compact ? 6 : 8
        let cellGap: CGFloat = compact ? 6 : 12
        // Core's message bar is 84 pt. A narrow screen has the board's own
        // row instead: the 44 pt sentence strip over 60 pt compact controls,
        // inside the same ring padding as every other scanned row.
        let messageHeight: CGFloat = compact ? 44 + 6 + 60 + GridIDs.rowPadding * 2 : 84
        let quickHeight: CGFloat = compact ? 76 : 88
        let topicsLines = compact ? 2 : 1
        let topicsLineHeight: CGFloat = compact ? 46 : 56
        let headerHeight: CGFloat = compact ? 28 : 30
        let chrome = GridIDs.rowPadding * 2
        let topicsHeight = CGFloat(topicsLines) * topicsLineHeight + CGFloat(topicsLines - 1) * cellGap
        let scannedRows: CGFloat = quickHeight + topicsHeight + 2 * chrome
        // Five gaps, and the padding above and below the rows.
        let spacing: CGFloat = 5 * gutter + 18
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

/// The whole board — Holos Grid's grid — top to bottom in scan order.
struct GridBoardView: View {
    let board: GridBoard
    let isScanning: Bool
    /// Where the guide's tag goes, during a guided turn only.
    let guide: GuideTarget?

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
        GeometryReader { proxy in
            let metrics = BoardMetrics(size: proxy.size)
            // Measured, not only predicted: at large text sizes the message
            // bar grows past the fixed budget, and a board that overflows
            // without knowing it would leave a lit bottom row off screen.
            let scrolls = metrics.needsScroll || contentHeight > proxy.size.height + Self.overflowTolerance
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing: metrics.gutter) {
                        MessageRow(board: board, isScanning: isScanning, metrics: metrics, target: guide)
                            .id(MessageBar.rowID)
                        QuickRow(board: board, isScanning: isScanning, metrics: metrics)
                            .id(GridIDs.quickRow)
                        TopicsRow(board: board, isScanning: isScanning, metrics: metrics, target: guide)
                            .id(GridIDs.topicsRow)
                        TopicHeader(board: board, metrics: metrics)
                        PhraseRow(
                            rowID: GridIDs.topicRowOne, number: 1, phrases: board.firstRow,
                            board: board, isScanning: isScanning, metrics: metrics, target: guide
                        )
                        .id(GridIDs.topicRowOne)
                        PhraseRow(
                            rowID: GridIDs.topicRowTwo, number: 2, phrases: board.secondRow,
                            board: board, isScanning: isScanning, metrics: metrics, target: guide
                        )
                        .id(GridIDs.topicRowTwo)
                    }
                    // Room above the first row for the guide's tag and the
                    // lit message bar's lift.
                    .padding(.top, 14)
                    .padding(.bottom, 4)
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
                // the guide's tags draw past the edge instead of being cut.
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

#Preview("Board — iPad, guided", traits: .landscapeLeft) {
    let experience = Experience.preview(.conversation, boardOpen: true)
    return GridBoardView(board: experience.board, isScanning: true, guide: experience.boardGuideTarget)
        .padding()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}

#Preview("Board — touch, free") {
    let experience = Experience.preview(.free)
    return GridBoardView(board: experience.board, isScanning: false, guide: nil)
        .padding()
        .background(BedsideTheme.background)
        .environment(experience)
        .holos(experience.services)
}
