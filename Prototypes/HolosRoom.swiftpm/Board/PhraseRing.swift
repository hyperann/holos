import SwiftUI

/// Where the cells of a ring go.
///
/// They fan out on an arc that faces the middle of the room, so a ring
/// around the door opens leftwards and a ring around the window opens to
/// the right — never off the edge. Clamping to the room can still push two
/// cells together, so a few rounds of nudging pull any overlap apart.
enum RingLayout {
    static func positions(count: Int, around center: CGPoint, radius: CGFloat, cell: CGSize, in bounds: CGRect) -> [CGPoint] {
        guard count > 0 else { return [] }
        guard bounds.width > cell.width + 12, bounds.height > cell.height + 12 else {
            return Array(repeating: CGPoint(x: bounds.midX, y: bounds.midY), count: count)
        }
        let towardsMiddle = atan2(Double(bounds.midY - center.y), Double(bounds.midX - center.x))
        let span = min(Double.pi * 1.3, Double(count - 1) * 0.9)
        let step = count > 1 ? span / Double(count - 1) : 0
        let start = towardsMiddle - span / 2
        let inset = bounds.insetBy(dx: cell.width / 2 + 6, dy: cell.height / 2 + 6)

        func clamped(_ point: CGPoint) -> CGPoint {
            CGPoint(x: min(max(point.x, inset.minX), inset.maxX), y: min(max(point.y, inset.minY), inset.maxY))
        }

        var points = (0..<count).map { index -> CGPoint in
            let angle = start + step * Double(index)
            return clamped(CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            ))
        }

        let gap: CGFloat = 10
        for _ in 0..<24 {
            var moved = false
            for first in points.indices {
                for second in points.indices where second > first {
                    let dx = points[second].x - points[first].x
                    let dy = points[second].y - points[first].y
                    let overlapX = cell.width + gap - abs(dx)
                    let overlapY = cell.height + gap - abs(dy)
                    guard overlapX > 0, overlapY > 0 else { continue }
                    moved = true
                    // Push apart along whichever axis needs the smaller move.
                    if overlapX < overlapY {
                        let push = overlapX / 2 * (dx >= 0 ? 1 : -1)
                        points[first].x -= push
                        points[second].x += push
                    } else {
                        let push = overlapY / 2 * (dy >= 0 ? 1 : -1)
                        points[first].y -= push
                        points[second].y += push
                    }
                }
            }
            points = points.map(clamped)
            if !moved { break }
        }
        return points
    }

    /// Cells follow the room's scale, within limits that keep words readable
    /// and the ring inside the room.
    static func cellSize(scale: CGFloat) -> CGSize {
        let width = min(max(150 * scale, 108), 172)
        return CGSize(width: width, height: width * 0.84)
    }
}

/// The ring itself, blooming over the room on wide screens.
struct RingLayer: View {
    let size: CGSize
    let scale: CGFloat

    @Environment(Experience.self) private var experience
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let items = experience.ringItems
        if let spot = experience.openHotspot, !items.isEmpty {
            let cell = RingLayout.cellSize(scale: scale)
            let center = spot.frame.center.scaled(scale)
            let points = RingLayout.positions(
                count: items.count,
                around: center,
                radius: 228 * scale,
                cell: cell,
                in: CGRect(origin: .zero, size: size)
            )
            let anchor = UnitPoint(
                x: size.width > 0 ? center.x / size.width : 0.5,
                y: size.height > 0 ? center.y / size.height : 0.5
            )
            // Blooms out of the object itself; a plain fade under Reduce Motion.
            let bloom: AnyTransition = reduceMotion ? .opacity : .scale(scale: 0.6, anchor: anchor).combined(with: .opacity)
            ZStack(alignment: .topLeading) {
                // Threads from the object to its words: these sentences
                // belong to that bed, that photo.
                Path { path in
                    for point in points {
                        path.move(to: center)
                        path.addLine(to: point)
                    }
                }
                .stroke(HolosTheme.highlight.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 9]))
                .accessibilityHidden(true)
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    RingCell(item: item)
                        .frame(width: cell.width, height: cell.height)
                        .position(points.indices.contains(index) ? points[index] : center)
                }
            }
            .frame(width: size.width, height: size.height)
            // A new id per open group, so the person in the photo blooms
            // fresh rather than morphing out of the photo's own ring.
            .id(items.map(\.id).joined(separator: "|"))
            .transition(bloom)
        }
    }
}

/// The ring as a sheet of cells under the room, for narrow screens where a
/// ring around a thumbnail-sized bed would cover the whole picture.
struct RingSheet: View {
    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let items = experience.ringItems
        if let spot = experience.openHotspot, !items.isEmpty {
            let language = settings.language
            let gender = settings.gender
            let rise: AnyTransition = reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let topic = experience.board.openTopic(isScanning: experience.isScanning) {
                        spot.name.text(language) + Text(" · ") + topic.phrase.label.text(language, gender)
                    } else {
                        spot.name.text(language)
                    }
                }
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(HolosTheme.highlight)
                .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(items) { item in
                        RingCell(item: item)
                            .frame(height: 88)
                    }
                }
            }
            .padding(10)
            .background(RoomTheme.shelf(contrast), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .id(items.map(\.id).joined(separator: "|"))
            .transition(rise)
        }
    }
}

/// One cell of a ring: a phrase, a person in the photo, or "go back".
struct RingCell: View {
    let item: RingItem

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        let isLit = experience.litID == item.id
        let isGuide = experience.guideID == item.id
        Group {
            if let choice = item.choice {
                SymbolCell(
                    phrase: choice.phrase,
                    isHighlighted: isLit,
                    hint: choice.opensMore ? Copy.topicHint : CoreCopy.cellHintSpeak
                ) {
                    experience.touchRing(item)
                }
                .overlay(alignment: .bottomTrailing) {
                    if choice.opensMore {
                        MoreBadge()
                    }
                }
            } else {
                BackCell(isHighlighted: isLit) {
                    experience.touchRing(item)
                }
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
        .overlay(alignment: .top) {
            if isGuide {
                GuideMarker().offset(y: -22)
            }
        }
        .accessibilityValue(isGuide ? Copy.nextStep.text(settings.language) : Text(""))
        // A ring left open behind a story card does nothing when touched,
        // so VoiceOver does not offer it either.
        .accessibilityHidden(experience.boardMode == .inert)
    }
}

/// Marks a cell that opens more choices rather than speaking.
struct MoreBadge: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(Color.white)
            .frame(width: 26, height: 26)
            .background(WordKind.people.ink, in: Circle())
            .padding(6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Ring cells") {
    let services = HolosServices.preview()
    let experience = Experience(services: services)
    let items = Vocabulary.ward[1].choices.map { RingItem(id: $0.id, choice: $0) }
    return HStack(spacing: 12) {
        ForEach(items) { item in
            RingCell(item: item).frame(width: 140, height: 118)
        }
        RingCell(item: RingItem(id: "ward.bed#back", choice: nil)).frame(width: 140, height: 118)
    }
    .padding(30)
    .background(Color.black)
    .holos(services)
    .environment(experience)
}
