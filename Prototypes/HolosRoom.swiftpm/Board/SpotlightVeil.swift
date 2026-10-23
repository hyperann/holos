import SwiftUI

/// A dark veil over the room with one rounded hole in it: the spotlight.
///
/// The scan highlight on a grid is a ring around a cell. In a room, a ring
/// alone gets lost among the furniture, so everything *else* goes dim
/// instead — the way a torch finds one thing in a dark room. The hole is
/// animatable, so with motion allowed the light glides from object to
/// object; under Reduce Motion `RoomCanvas` swaps veils with a fade.
///
/// The hole is stored as four numbers rather than a `CGRect`, so the shape
/// is plainly `Sendable` (Swift 6 requires it of every `Shape`).
struct SpotlightVeil: Shape {
    var holeX: CGFloat
    var holeY: CGFloat
    var holeWidth: CGFloat
    var holeHeight: CGFloat
    var cornerRadius: CGFloat

    /// - Parameter hole: The lit area, or nil for an even veil. A missing
    ///   hole shrinks to the middle, so the light closes like an iris.
    init(hole: CGRect?, in size: CGSize, cornerRadius: CGFloat) {
        let rect = hole ?? CGRect(x: size.width / 2, y: size.height / 2, width: 0, height: 0)
        holeX = rect.minX
        holeY = rect.minY
        holeWidth = rect.width
        holeHeight = rect.height
        self.cornerRadius = cornerRadius
    }

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(AnimatablePair(holeX, holeY), AnimatablePair(holeWidth, holeHeight))
        }
        set {
            holeX = newValue.first.first
            holeY = newValue.first.second
            holeWidth = newValue.second.first
            holeHeight = newValue.second.second
        }
    }

    /// Filled with `FillStyle(eoFill: true)`, the inner rectangle becomes a hole.
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        if holeWidth > 1, holeHeight > 1 {
            let radius = min(cornerRadius, holeWidth / 2, holeHeight / 2)
            path.addRoundedRect(
                in: CGRect(x: holeX, y: holeY, width: holeWidth, height: holeHeight),
                cornerSize: CGSize(width: radius, height: radius)
            )
        }
        return path
    }
}

#Preview("Spotlight") {
    ZStack {
        Color.teal
        SpotlightVeil(hole: CGRect(x: 80, y: 60, width: 160, height: 120), in: CGSize(width: 400, height: 280), cornerRadius: 24)
            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
    }
    .frame(width: 400, height: 280)
}
