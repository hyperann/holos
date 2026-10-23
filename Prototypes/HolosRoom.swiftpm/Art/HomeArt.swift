import SwiftUI

/// Home at dusk, drawn in room space (1000 × 700).
///
/// The family photo is the heart of this room — it is where the word Yuriy
/// cannot recall is waiting — so it hangs at eye height in the warmest
/// light. The person sits on the sofa: their speech bubble comes from there.
/// Positions match the hotspot frames in `Vocabulary+Home`.
struct HomeArt: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoomShell(wall: Dusk.homeWall, wallLow: Dusk.homeWallLow)
            // The floor lamp's light, and the rug it falls on.
            Glow(strength: 0.48).artFrame(440, 20, 620, 600)
            Ellipse().fill(Dusk.rug).artFrame(380, 596, 400, 70)
            Ellipse().stroke(Dusk.lamp.opacity(0.35), lineWidth: 3).artFrame(400, 604, 360, 54)
            fridge
            kitchen
            photo
            television
            floorLamp
            sofa
            frontDoor
            Vignette()
        }
        .frame(width: 1000, height: 700)
        .accessibilityHidden(true)
    }

    private var fridge: some View {
        ZStack(alignment: .topLeading) {
            FloorShadow().artFrame(26, 576, 160, 26)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Dusk.fridge, Dusk.fridgeShade], startPoint: .leading, endPoint: .trailing))
                .artFrame(30, 170, 150, 420)
            Rectangle().fill(Dusk.fridgeShade).artFrame(30, 318, 150, 4)
            Capsule().fill(Dusk.metalShade).artFrame(158, 232, 8, 66)
            Capsule().fill(Dusk.metalShade).artFrame(158, 342, 8, 110)
            // A child's drawing held up by magnets.
            RoundedRectangle(cornerRadius: 3).fill(Dusk.paper).artFrame(58, 356, 56, 70, rotation: .degrees(-4))
            Image(systemName: "sun.max.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.pills)
                .artFrame(70, 366, 30, 30)
            Image(systemName: "house.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.kettle)
                .artFrame(74, 398, 24, 22)
            Circle().fill(Dusk.alarm).artFrame(80, 350, 10, 10)
            Circle().fill(Dusk.leaf).artFrame(120, 250, 12, 12)
            Circle().fill(Dusk.blanket).artFrame(60, 270, 12, 12)
        }
        .frame(width: 1000, height: 700)
    }

    private var kitchen: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6).fill(Dusk.wood).artFrame(196, 150, 158, 100)
            Rectangle().fill(Dusk.darkWood.opacity(0.5)).artFrame(274, 156, 2, 88)
            Capsule().fill(Dusk.metal).artFrame(262, 228, 6, 14)
            Capsule().fill(Dusk.metal).artFrame(282, 228, 6, 14)
            Rectangle().fill(Dusk.tile).artFrame(190, 262, 170, 150)
            TileGrid().stroke(Color.white.opacity(0.45), lineWidth: 1.5).artFrame(190, 262, 170, 150)
            FloorShadow().artFrame(190, 578, 172, 24)
            RoundedRectangle(cornerRadius: 6).fill(LinearGradient(colors: [Dusk.wood, Dusk.woodShade], startPoint: .top, endPoint: .bottom)).artFrame(196, 420, 158, 168)
            RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.86, green: 0.83, blue: 0.77)).artFrame(188, 410, 174, 14)
            RoundedRectangle(cornerRadius: 4).stroke(Dusk.darkWood.opacity(0.5), lineWidth: 2).artFrame(208, 436, 134, 52)
            RoundedRectangle(cornerRadius: 4).stroke(Dusk.darkWood.opacity(0.5), lineWidth: 2).artFrame(208, 498, 134, 76)
            Capsule().fill(Dusk.metal).artFrame(262, 456, 26, 7)
            kettle
            Image(systemName: "mug.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.paper)
                .artFrame(318, 382, 32, 28)
        }
        .frame(width: 1000, height: 700)
    }

    /// An enamel kettle, steaming a little: tea is a long conversation in
    /// a Ukrainian home.
    private var kettle: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Dusk.ink, lineWidth: 6).artFrame(248, 322, 50, 46)
            Quad(0, 0.55, 1, 0, 1, 0.2, 0, 1).fill(Dusk.kettle).artFrame(292, 350, 30, 40)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Dusk.kettle, Color(red: 0.62, green: 0.20, blue: 0.16)], startPoint: .top, endPoint: .bottom))
                .artFrame(236, 346, 74, 66)
            Capsule().fill(Color(red: 0.62, green: 0.20, blue: 0.16)).artFrame(250, 340, 46, 12)
            Circle().fill(Dusk.ink).artFrame(267, 330, 12, 12)
            Circle().fill(Color.white.opacity(0.85)).artFrame(254, 360, 12, 12)
            Capsule().fill(Color.white.opacity(0.25)).artFrame(318, 322, 8, 24)
            Capsule().fill(Color.white.opacity(0.18)).artFrame(326, 300, 7, 20)
        }
        .frame(width: 1000, height: 700)
    }

    /// The family photo — the cell that offers the word.
    private var photo: some View {
        ZStack(alignment: .topLeading) {
            Glow(color: Dusk.lamp, strength: 0.3).artFrame(390, 50, 230, 210)
            Path { path in
                path.move(to: CGPoint(x: 505, y: 70))
                path.addLine(to: CGPoint(x: 440, y: 92))
                path.move(to: CGPoint(x: 505, y: 70))
                path.addLine(to: CGPoint(x: 570, y: 92))
            }
            .stroke(Dusk.ink.opacity(0.6), lineWidth: 2)
            Circle().fill(Dusk.metalShade).artFrame(501, 66, 8, 8)
            Rectangle().fill(Color.black.opacity(0.25)).blur(radius: 3).artFrame(426, 96, 170, 130)
            RoundedRectangle(cornerRadius: 6).fill(Dusk.wood).artFrame(420, 90, 170, 130)
            Rectangle().fill(Dusk.paper).artFrame(430, 100, 150, 110)
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.62, green: 0.80, blue: 0.92), Color(red: 0.58, green: 0.76, blue: 0.50)], startPoint: .top, endPoint: .bottom))
                .artFrame(438, 108, 134, 94)
            Circle().fill(Dusk.lamp).artFrame(544, 114, 18, 18)
            Image(systemName: "figure.and.child.holdinghands")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.ink.opacity(0.85))
                .artFrame(446, 122, 72, 78)
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.kettle.opacity(0.9))
                .artFrame(516, 128, 46, 72)
        }
        .frame(width: 1000, height: 700)
    }

    private var television: some View {
        ZStack(alignment: .topLeading) {
            Glow(color: Dusk.screenGlow, strength: 0.25).artFrame(600, 90, 230, 180)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Dusk.screen).artFrame(620, 120, 190, 112)
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [Color(red: 0.12, green: 0.18, blue: 0.30), Color(red: 0.05, green: 0.07, blue: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .artFrame(628, 128, 174, 96)
            Quad(0.55, 0, 0.75, 0, 0.35, 1, 0.15, 1).fill(Color.white.opacity(0.06)).artFrame(628, 128, 174, 96)
            Rectangle().fill(Dusk.screen).artFrame(706, 232, 18, 10)
            Circle().fill(Color.red.opacity(0.8)).artFrame(798, 222, 5, 5)
        }
        .frame(width: 1000, height: 700)
    }

    private var floorLamp: some View {
        ZStack(alignment: .topLeading) {
            Ellipse().fill(Dusk.metalShade).artFrame(738, 576, 34, 10)
            Rectangle().fill(Dusk.metalShade).artFrame(753, 322, 5, 258)
            Glow(strength: 0.55).artFrame(690, 260, 130, 130)
            Trapezoid()
                .fill(LinearGradient(colors: [Dusk.lamp, Dusk.lampDeep], startPoint: .top, endPoint: .bottom))
                .artFrame(726, 280, 60, 44)
        }
        .frame(width: 1000, height: 700)
    }

    /// The sofa, and the person sitting on it.
    private var sofa: some View {
        ZStack(alignment: .topLeading) {
            FloorShadow().artFrame(404, 568, 316, 30)
            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Dusk.sofa).artFrame(420, 400, 280, 112)
            // The person: hair, face, jumper, trousers.
            Ellipse().fill(Dusk.greyHair).artFrame(476, 296, 60, 40)
            Ellipse().fill(Dusk.skin).artFrame(482, 304, 48, 54)
            Rectangle().fill(Dusk.skin).artFrame(498, 352, 16, 14)
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Dusk.sweater).artFrame(466, 362, 80, 112)
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Dusk.sofa).artFrame(432, 478, 128, 50)
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Dusk.sofa).artFrame(562, 478, 128, 50)
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Dusk.trousers).artFrame(474, 462, 84, 36)
            Capsule().fill(Dusk.sweater).artFrame(456, 400, 22, 74)
            Capsule().fill(Dusk.sweater).artFrame(534, 400, 22, 74)
            Circle().fill(Dusk.skin).artFrame(456, 462, 20, 18)
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Dusk.sofaShade).artFrame(404, 450, 40, 112)
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Dusk.sofaShade).artFrame(676, 450, 40, 112)
            Rectangle().fill(Dusk.sofaShade).artFrame(420, 526, 280, 30)
            Rectangle().fill(Dusk.darkWood).artFrame(428, 556, 10, 16)
            Rectangle().fill(Dusk.darkWood).artFrame(682, 556, 10, 16)
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Dusk.blanket).artFrame(628, 430, 48, 44, rotation: .degrees(10))
        }
        .frame(width: 1000, height: 700)
    }

    private var frontDoor: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Dusk.linenShade).artFrame(842, 106, 142, 420)
            RoundedRectangle(cornerRadius: 4).fill(Dusk.darkWood).artFrame(852, 116, 122, 410)
            Rectangle()
                .fill(LinearGradient(colors: [Dusk.skyTop, Dusk.skyMid, Dusk.skyLow], startPoint: .top, endPoint: .bottom))
                .artFrame(872, 140, 82, 110)
            Rectangle().fill(Dusk.darkWood).artFrame(911, 140, 4, 110)
            Rectangle().fill(Dusk.darkWood).artFrame(872, 193, 82, 4)
            RoundedRectangle(cornerRadius: 4).stroke(Dusk.woodShade, lineWidth: 3).artFrame(872, 290, 82, 90)
            RoundedRectangle(cornerRadius: 4).stroke(Dusk.woodShade, lineWidth: 3).artFrame(872, 400, 82, 100)
            Capsule().fill(Dusk.metal).artFrame(948, 318, 18, 7)
            Rectangle().fill(Dusk.rug).artFrame(848, 522, 130, 12)
        }
        .frame(width: 1000, height: 700)
    }
}

/// Kitchen tiles behind the kettle.
struct TileGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size: CGFloat = 25
        var x = rect.minX + size
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += size
        }
        var y = rect.minY + size
        while y < rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += size
        }
        return path
    }
}

#Preview("Home") {
    GeometryReader { geo in
        let scale = min(geo.size.width / RoomSpace.width, geo.size.height / RoomSpace.height)
        HomeArt()
            .scaleEffect(scale, anchor: .topLeading)
    }
    .aspectRatio(RoomSpace.aspect, contentMode: .fit)
    .padding()
}
