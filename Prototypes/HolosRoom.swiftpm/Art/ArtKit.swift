import SwiftUI

/// The dusk palette both rooms are painted in.
///
/// Dusk on purpose: deep teal walls make the warm lamp light read as
/// "evening, someone's room", and they let a dimmed scene stay calm while
/// the spotlit object glows. No image files — every room is drawn in code
/// from shapes, gradients and SF Symbols, so the playground ships nothing
/// that needs a licence and stays tiny.
enum Dusk {
    static let wall = Color(red: 0.06, green: 0.25, blue: 0.28)
    static let wallLow = Color(red: 0.10, green: 0.33, blue: 0.35)
    static let homeWall = Color(red: 0.08, green: 0.27, blue: 0.27)
    static let homeWallLow = Color(red: 0.13, green: 0.35, blue: 0.33)
    static let floorTop = Color(red: 0.47, green: 0.29, blue: 0.17)
    static let floorBottom = Color(red: 0.31, green: 0.18, blue: 0.10)
    static let plank = Color(red: 0.24, green: 0.14, blue: 0.08)
    static let skirting = Color(red: 0.04, green: 0.15, blue: 0.17)

    static let lamp = Color(red: 1.0, green: 0.82, blue: 0.50)
    static let lampDeep = Color(red: 0.98, green: 0.62, blue: 0.30)
    static let skyTop = Color(red: 0.17, green: 0.15, blue: 0.38)
    static let skyMid = Color(red: 0.60, green: 0.32, blue: 0.48)
    static let skyLow = Color(red: 0.98, green: 0.62, blue: 0.36)
    static let city = Color(red: 0.13, green: 0.11, blue: 0.24)

    static let curtain = Color(red: 0.82, green: 0.46, blue: 0.30)
    static let curtainShade = Color(red: 0.60, green: 0.28, blue: 0.19)
    static let linen = Color(red: 0.94, green: 0.93, blue: 0.89)
    static let linenShade = Color(red: 0.76, green: 0.78, blue: 0.77)
    static let blanket = Color(red: 0.36, green: 0.55, blue: 0.71)
    static let blanketShade = Color(red: 0.24, green: 0.40, blue: 0.56)
    static let metal = Color(red: 0.72, green: 0.77, blue: 0.80)
    static let metalShade = Color(red: 0.45, green: 0.51, blue: 0.55)
    static let wood = Color(red: 0.68, green: 0.47, blue: 0.30)
    static let woodShade = Color(red: 0.48, green: 0.31, blue: 0.19)
    static let darkWood = Color(red: 0.34, green: 0.21, blue: 0.13)

    static let skin = Color(red: 0.93, green: 0.74, blue: 0.60)
    static let hair = Color(red: 0.27, green: 0.18, blue: 0.13)
    static let greyHair = Color(red: 0.62, green: 0.60, blue: 0.58)
    static let scrubs = Color(red: 0.56, green: 0.81, blue: 0.80)
    static let scrubsShade = Color(red: 0.40, green: 0.64, blue: 0.65)
    static let sweater = Color(red: 0.47, green: 0.57, blue: 0.35)
    static let trousers = Color(red: 0.24, green: 0.28, blue: 0.36)

    static let paper = Color(red: 0.97, green: 0.94, blue: 0.87)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.14)
    static let glass = Color(red: 0.78, green: 0.91, blue: 0.96)
    static let water = Color(red: 0.42, green: 0.70, blue: 0.92)
    static let pills = Color(red: 0.95, green: 0.56, blue: 0.20)
    static let alarm = Color(red: 0.86, green: 0.26, blue: 0.24)
    static let leaf = Color(red: 0.42, green: 0.66, blue: 0.40)
    static let screen = Color(red: 0.07, green: 0.09, blue: 0.13)
    static let screenGlow = Color(red: 0.35, green: 0.62, blue: 0.86)
    static let corridor = Color(red: 1.0, green: 0.94, blue: 0.80)
    static let sofa = Color(red: 0.83, green: 0.56, blue: 0.27)
    static let sofaShade = Color(red: 0.64, green: 0.40, blue: 0.18)
    static let fridge = Color(red: 0.91, green: 0.93, blue: 0.91)
    static let fridgeShade = Color(red: 0.74, green: 0.78, blue: 0.77)
    static let tile = Color(red: 0.80, green: 0.85, blue: 0.82)
    static let rug = Color(red: 0.56, green: 0.24, blue: 0.25)
    static let kettle = Color(red: 0.80, green: 0.30, blue: 0.24)
}

extension View {
    /// Places one piece of a room by its frame in room space (1000 × 700).
    ///
    /// The rotation comes before the position on purpose: rotating after
    /// `.position` would swing the piece around the middle of the whole room.
    func artFrame(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, rotation: Angle = .zero) -> some View {
        frame(width: width, height: height)
            .rotationEffect(rotation)
            .position(x: x + width / 2, y: y + height / 2)
    }
}

// MARK: - Shared pieces

/// Wall, floorboards and skirting: the box every room is drawn in.
struct RoomShell: View {
    var wall = Dusk.wall
    var wallLow = Dusk.wallLow

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(LinearGradient(colors: [wall, wallLow], startPoint: .top, endPoint: .bottom))
                .artFrame(0, 0, 1000, 530)
            Rectangle()
                .fill(LinearGradient(colors: [Dusk.floorTop, Dusk.floorBottom], startPoint: .top, endPoint: .bottom))
                .artFrame(0, 520, 1000, 180)
            FloorBoards()
                .stroke(Dusk.plank.opacity(0.5), lineWidth: 2)
                .artFrame(0, 520, 1000, 180)
            Rectangle()
                .fill(Dusk.skirting)
                .artFrame(0, 512, 1000, 14)
        }
        .frame(width: 1000, height: 700)
    }
}

/// Warm light falling on the wall around a lamp.
struct Glow: View {
    var color = Dusk.lamp
    var strength = 0.5

    var body: some View {
        Ellipse()
            .fill(EllipticalGradient(
                colors: [color.opacity(strength), color.opacity(strength * 0.35), color.opacity(0)],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            ))
    }
}

/// The soft dark pool under a piece of furniture.
struct FloorShadow: View {
    var opacity = 0.32

    var body: some View {
        Ellipse()
            .fill(Color.black.opacity(opacity))
            .blur(radius: 8)
    }
}

/// Darkened corners, so the middle of the room feels lit.
struct Vignette: View {
    var body: some View {
        Rectangle()
            .fill(EllipticalGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.6),
                    .init(color: Color.black.opacity(0.38), location: 1),
                ]),
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.72
            ))
            .frame(width: 1000, height: 700)
    }
}

// MARK: - Shapes

/// Floorboards in perspective: the seams get further apart towards the viewer.
struct FloorBoards: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let seams: [CGFloat] = [0.12, 0.27, 0.45, 0.68, 0.94]
        for seam in seams {
            let y = rect.minY + rect.height * seam
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        // A few board ends, staggered like real flooring.
        let joints: [(CGFloat, CGFloat, CGFloat)] = [
            (0.18, 0.0, 0.12), (0.52, 0.0, 0.12), (0.83, 0.0, 0.12),
            (0.33, 0.12, 0.27), (0.71, 0.12, 0.27),
            (0.10, 0.27, 0.45), (0.47, 0.27, 0.45), (0.90, 0.27, 0.45),
            (0.27, 0.45, 0.68), (0.64, 0.45, 0.68),
            (0.05, 0.68, 0.94), (0.41, 0.68, 0.94), (0.78, 0.68, 0.94),
        ]
        for joint in joints {
            let x = rect.minX + rect.width * joint.0
            path.move(to: CGPoint(x: x, y: rect.minY + rect.height * joint.1))
            path.addLine(to: CGPoint(x: x, y: rect.minY + rect.height * joint.2))
        }
        return path
    }
}

/// A curtain panel: straight top, softly scalloped hem.
struct Drape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let hem = rect.maxY - rect.height * 0.04
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: hem))
        let scallops = 3
        let width = rect.width / CGFloat(scallops)
        for index in 0..<scallops {
            let endX = rect.maxX - width * CGFloat(index + 1)
            path.addQuadCurve(
                to: CGPoint(x: endX, y: hem),
                control: CGPoint(x: endX + width / 2, y: rect.maxY + rect.height * 0.03)
            )
        }
        path.closeSubpath()
        return path
    }
}

/// A lamp shade: narrow at the top, wide at the bottom.
struct Trapezoid: Shape {
    var topInset: CGFloat = 0.22

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * topInset
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Any four-cornered shape, corners given as fractions of its frame,
/// clockwise from the top left: a door swung open, light spilling on a floor.
struct Quad: Shape {
    let corners: [CGFloat]

    init(_ corners: CGFloat...) {
        self.corners = corners
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard corners.count == 8 else { return path }
        func point(_ index: Int) -> CGPoint {
            CGPoint(
                x: rect.minX + rect.width * corners[index * 2],
                y: rect.minY + rect.height * corners[index * 2 + 1]
            )
        }
        path.move(to: point(0))
        path.addLine(to: point(1))
        path.addLine(to: point(2))
        path.addLine(to: point(3))
        path.closeSubpath()
        return path
    }
}

/// A blanket over someone lying down: a rise at the chest, the knees, the feet.
struct BlanketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY
        path.move(to: CGPoint(x: x, y: y + h * 0.28))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.42, y: y + h * 0.24), control: CGPoint(x: x + w * 0.2, y: y + h * 0.04))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.74, y: y + h * 0.06), control: CGPoint(x: x + w * 0.6, y: y + h * 0.34))
        path.addQuadCurve(to: CGPoint(x: x + w, y: y + h * 0.36), control: CGPoint(x: x + w * 0.95, y: y))
        path.addLine(to: CGPoint(x: x + w, y: y + h))
        path.addLine(to: CGPoint(x: x, y: y + h))
        path.closeSubpath()
        return path
    }
}

/// A small triangle: a speech bubble's tail, a shelf bracket.
struct Triangle: Shape {
    var pointsUp = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

#Preview("Room shell") {
    ZStack(alignment: .topLeading) {
        RoomShell()
        Glow().artFrame(500, 150, 400, 400)
        Drape().fill(Dusk.curtain).artFrame(80, 60, 80, 260)
        Trapezoid().fill(Dusk.lamp).artFrame(680, 300, 70, 50)
        BlanketShape().fill(Dusk.blanket).artFrame(250, 420, 320, 80)
        Quad(0, 0, 1, 0.1, 1, 0.9, 0, 1).fill(Dusk.wood).artFrame(860, 100, 40, 400)
        Vignette()
    }
    .frame(width: 1000, height: 700)
    .scaleEffect(0.6)
}
