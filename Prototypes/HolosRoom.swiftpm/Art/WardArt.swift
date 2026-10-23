import SwiftUI

/// The hospital ward at dusk, drawn in room space (1000 × 700).
///
/// Everything a person in that bed would look at is here and nothing else:
/// the window, the body chart, the phone, the bedside table, the nurse in
/// the doorway. A scene board works because these are already the objects
/// the person thinks with — so the picture must be quiet enough that each
/// one is easy to find when the light lands on it. Positions match the
/// hotspot frames in `Vocabulary+Ward`.
struct WardArt: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoomShell()
            // The bedside lamp's light on the wall.
            Glow(strength: 0.42).artFrame(470, 60, 570, 560)
            window
            radiator
            bodyChart
            phoneShelf
            doorway
            nurse
            bed
            bedsideTable
            Vignette()
        }
        .frame(width: 1000, height: 700)
        .accessibilityHidden(true)
    }

    private var window: some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(Dusk.metalShade).artFrame(24, 50, 292, 8)
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Dusk.linen).artFrame(50, 70, 230, 240)
            Rectangle()
                .fill(LinearGradient(colors: [Dusk.skyTop, Dusk.skyMid, Dusk.skyLow], startPoint: .top, endPoint: .bottom))
                .artFrame(62, 82, 206, 216)
            Circle().fill(Color.white.opacity(0.85)).artFrame(110, 100, 4, 4)
            Circle().fill(Color.white.opacity(0.7)).artFrame(146, 120, 3, 3)
            Circle().fill(Color.white.opacity(0.8)).artFrame(214, 96, 4, 4)
            Circle().fill(Dusk.lamp.opacity(0.95)).artFrame(178, 216, 46, 46)
            Rectangle().fill(Dusk.city).artFrame(96, 230, 38, 68)
            Rectangle().fill(Dusk.city).artFrame(132, 256, 46, 42)
            Rectangle().fill(Dusk.city).artFrame(176, 240, 30, 58)
            Rectangle().fill(Dusk.city).artFrame(204, 262, 46, 36)
            Rectangle().fill(Dusk.lamp.opacity(0.9)).artFrame(108, 244, 5, 6)
            Rectangle().fill(Dusk.lamp.opacity(0.9)).artFrame(120, 264, 5, 6)
            Rectangle().fill(Dusk.lamp.opacity(0.9)).artFrame(186, 252, 5, 6)
            Rectangle().fill(Dusk.lamp.opacity(0.9)).artFrame(222, 274, 5, 6)
            Rectangle().fill(Dusk.linen).artFrame(162, 82, 6, 216)
            Rectangle().fill(Dusk.linen).artFrame(62, 186, 206, 6)
            RoundedRectangle(cornerRadius: 3).fill(Dusk.linenShade).artFrame(40, 304, 250, 14)
            curtain(x: 26)
            curtain(x: 244)
        }
        .frame(width: 1000, height: 700)
    }

    private func curtain(x: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Drape()
                .fill(LinearGradient(colors: [Dusk.curtain, Dusk.curtainShade], startPoint: .leading, endPoint: .trailing))
                .artFrame(x, 56, 70, 274)
            Rectangle().fill(Dusk.curtainShade.opacity(0.5)).artFrame(x + 22, 60, 3, 258)
            Rectangle().fill(Dusk.curtainShade.opacity(0.5)).artFrame(x + 46, 60, 3, 258)
        }
        .frame(width: 1000, height: 700)
    }

    private var radiator: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Dusk.linenShade).artFrame(36, 396, 100, 96)
            ForEach(0..<6, id: \.self) { index in
                Capsule().fill(Dusk.metalShade.opacity(0.5)).artFrame(46 + CGFloat(index) * 15, 404, 6, 80)
            }
            Rectangle().fill(Dusk.metalShade).artFrame(60, 492, 6, 22)
        }
        .frame(width: 1000, height: 700)
    }

    /// A pain body chart: pointing at where it hurts is easier than naming it.
    private var bodyChart: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Color.black.opacity(0.25)).blur(radius: 3).artFrame(366, 88, 130, 180)
            RoundedRectangle(cornerRadius: 4).fill(Dusk.paper).artFrame(360, 80, 130, 180)
            Capsule().fill(Dusk.blanketShade.opacity(0.55)).artFrame(374, 94, 102, 7)
            Capsule().fill(Dusk.blanketShade.opacity(0.35)).artFrame(374, 106, 64, 5)
            Image(systemName: "figure.arms.open")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.blanketShade)
                .artFrame(372, 118, 106, 132)
            Circle().fill(Dusk.alarm).artFrame(421, 74, 9, 9)
        }
        .frame(width: 1000, height: 700)
    }

    private var phoneShelf: some View {
        ZStack(alignment: .topLeading) {
            Glow(color: Dusk.screenGlow, strength: 0.35).artFrame(568, 140, 130, 130)
            RoundedRectangle(cornerRadius: 3).fill(Dusk.wood).artFrame(560, 250, 150, 12)
            Triangle().fill(Dusk.woodShade).artFrame(574, 262, 18, 16)
            Triangle().fill(Dusk.woodShade).artFrame(678, 262, 18, 16)
            RoundedRectangle(cornerRadius: 4).fill(Dusk.curtainShade).artFrame(570, 226, 28, 24)
            Image(systemName: "leaf.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.leaf)
                .artFrame(566, 192, 36, 36)
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Dusk.screen).artFrame(612, 156, 54, 94)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: [Dusk.screenGlow, Dusk.blanketShade], startPoint: .top, endPoint: .bottom))
                .artFrame(616, 164, 46, 76)
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.white.opacity(0.9))
                .artFrame(626, 176, 26, 26)
            Circle().fill(Dusk.leaf).artFrame(630, 214, 18, 18)
        }
        .frame(width: 1000, height: 700)
    }

    private var doorway: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Dusk.linenShade).artFrame(806, 86, 168, 440)
            Rectangle()
                .fill(LinearGradient(colors: [Dusk.corridor, Color(red: 0.93, green: 0.80, blue: 0.60)], startPoint: .top, endPoint: .bottom))
                .artFrame(818, 98, 144, 428)
            Rectangle().fill(Color(red: 0.84, green: 0.72, blue: 0.56)).artFrame(818, 470, 144, 56)
            Rectangle().fill(Dusk.metal.opacity(0.6)).artFrame(818, 360, 144, 5)
            // The door, swung open towards the room.
            Quad(0, 0.03, 1, 0, 1, 1, 0, 0.97).fill(Dusk.wood).artFrame(962, 84, 34, 456)
            // Corridor light spilling across the floor.
            Quad(0.24, 0, 0.84, 0, 1, 1, 0, 1).fill(Dusk.corridor.opacity(0.22)).artFrame(760, 526, 240, 120)
        }
        .frame(width: 1000, height: 700)
    }

    private var nurse: some View {
        ZStack(alignment: .topLeading) {
            FloorShadow(opacity: 0.25).artFrame(846, 506, 90, 16)
            Capsule().fill(Dusk.scrubsShade).artFrame(868, 392, 18, 118)
            Capsule().fill(Dusk.scrubsShade).artFrame(894, 392, 18, 118)
            Capsule().fill(Color.white).artFrame(862, 504, 26, 11)
            Capsule().fill(Color.white).artFrame(892, 504, 26, 11)
            Capsule().fill(Dusk.scrubsShade).artFrame(842, 220, 20, 142)
            Capsule().fill(Dusk.scrubsShade).artFrame(918, 220, 20, 142)
            Circle().fill(Dusk.skin).artFrame(843, 350, 18, 18)
            Circle().fill(Dusk.skin).artFrame(919, 350, 18, 18)
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Dusk.scrubs).artFrame(852, 208, 76, 200)
            Triangle().fill(Dusk.skin).artFrame(880, 208, 20, 18)
            RoundedRectangle(cornerRadius: 4).fill(Color.white).artFrame(902, 236, 18, 18)
            Image(systemName: "cross.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.alarm)
                .artFrame(905, 239, 12, 12)
            Rectangle().fill(Dusk.skin).artFrame(882, 190, 16, 22)
            Ellipse().fill(Dusk.hair).artFrame(860, 138, 60, 56)
            Circle().fill(Dusk.hair).artFrame(906, 132, 22, 22)
            Ellipse().fill(Dusk.skin).artFrame(866, 146, 48, 52)
            Capsule().fill(Dusk.hair).artFrame(864, 142, 52, 16)
        }
        .frame(width: 1000, height: 700)
    }

    /// The bed, and the person in it: this is whose voice the board is.
    private var bed: some View {
        ZStack(alignment: .topLeading) {
            FloorShadow().artFrame(150, 566, 440, 42)
            RoundedRectangle(cornerRadius: 8).fill(Dusk.metal).artFrame(150, 344, 26, 216)
            Capsule().fill(Dusk.metalShade).artFrame(146, 336, 34, 12)
            RoundedRectangle(cornerRadius: 8).fill(Dusk.metal).artFrame(556, 404, 22, 156)
            Capsule().fill(Dusk.metalShade).artFrame(552, 396, 30, 11)
            Rectangle().fill(Dusk.metalShade).artFrame(170, 488, 392, 18)
            Rectangle().fill(Dusk.metalShade).artFrame(188, 506, 8, 46)
            Rectangle().fill(Dusk.metalShade).artFrame(538, 506, 8, 46)
            Circle().fill(Dusk.ink).artFrame(182, 548, 20, 20)
            Circle().fill(Dusk.ink).artFrame(532, 548, 20, 20)
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Dusk.linen).artFrame(172, 444, 388, 50)
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Dusk.linen).artFrame(180, 414, 104, 42)
            RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Dusk.linenShade, lineWidth: 2).artFrame(180, 414, 104, 42)
            Ellipse().fill(Dusk.hair).artFrame(196, 386, 56, 50)
            Ellipse().fill(Dusk.skin).artFrame(204, 392, 48, 46)
            BlanketShape()
                .fill(LinearGradient(colors: [Dusk.blanket, Dusk.blanketShade], startPoint: .top, endPoint: .bottom))
                .artFrame(236, 404, 330, 92)
            RoundedRectangle(cornerRadius: 8).fill(Dusk.linen).artFrame(234, 428, 26, 66)
            Capsule().fill(Dusk.skin).artFrame(258, 444, 70, 14)
            Capsule().fill(Dusk.metal.opacity(0.95)).artFrame(296, 452, 208, 8)
            Capsule().fill(Dusk.metal.opacity(0.95)).artFrame(304, 452, 7, 40)
            Capsule().fill(Dusk.metal.opacity(0.95)).artFrame(490, 452, 7, 40)
        }
        .frame(width: 1000, height: 700)
    }

    private var bedsideTable: some View {
        ZStack(alignment: .topLeading) {
            FloorShadow().artFrame(604, 574, 176, 28)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [Dusk.wood, Dusk.woodShade], startPoint: .top, endPoint: .bottom))
                .artFrame(612, 420, 156, 166)
            RoundedRectangle(cornerRadius: 4).fill(Dusk.wood).artFrame(606, 412, 168, 14)
            RoundedRectangle(cornerRadius: 4).stroke(Dusk.darkWood.opacity(0.6), lineWidth: 2).artFrame(624, 438, 132, 44)
            Capsule().fill(Dusk.metal).artFrame(678, 456, 24, 8)
            RoundedRectangle(cornerRadius: 4).stroke(Dusk.darkWood.opacity(0.5), lineWidth: 2).artFrame(624, 494, 132, 78)
            // A glass of water…
            RoundedRectangle(cornerRadius: 4).fill(Dusk.glass.opacity(0.75)).artFrame(622, 370, 34, 42)
            Rectangle().fill(Dusk.water.opacity(0.85)).artFrame(625, 386, 28, 24)
            // …the pills…
            RoundedRectangle(cornerRadius: 4).fill(Dusk.pills).artFrame(664, 378, 28, 34)
            RoundedRectangle(cornerRadius: 2).fill(Color.white).artFrame(662, 368, 32, 12)
            Rectangle().fill(Color.white.opacity(0.85)).artFrame(667, 388, 22, 12)
            // …and the glasses.
            Image(systemName: "eyeglasses")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Dusk.ink)
                .artFrame(694, 394, 38, 18)
            Glow(strength: 0.6).artFrame(676, 296, 150, 150)
            Ellipse().fill(Dusk.metalShade).artFrame(738, 404, 34, 10)
            Rectangle().fill(Dusk.metalShade).artFrame(752, 352, 6, 54)
            Trapezoid()
                .fill(LinearGradient(colors: [Dusk.lamp, Dusk.lampDeep], startPoint: .top, endPoint: .bottom))
                .artFrame(724, 312, 62, 44)
        }
        .frame(width: 1000, height: 700)
    }
}

#Preview("Ward") {
    GeometryReader { geo in
        let scale = min(geo.size.width / RoomSpace.width, geo.size.height / RoomSpace.height)
        WardArt()
            .scaleEffect(scale, anchor: .topLeading)
    }
    .aspectRatio(RoomSpace.aspect, contentMode: .fit)
    .padding()
}
