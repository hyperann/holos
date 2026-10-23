import Foundation
import SwiftUI

/// The compass at the heart of the board: a needle that points at whatever
/// is lit.
///
/// It is not decoration. For someone who has lost reading, the needle says
/// *where* the light is without a word: it swings clockwise with the scan
/// and, in head-pointing mode, follows the head. Under Reduce Motion it
/// jumps instead of swinging.
struct NeedleDial: View {
    /// The direction to point at; `nil` when the centre itself is lit.
    let target: Direction?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    /// Accumulates rather than wrapping at 360°, so going from west back to
    /// north is a quarter turn forward, never three quarters backwards.
    @State private var angle: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(CompassTheme.background)
            Circle()
                .strokeBorder(CompassTheme.keyline(contrast), lineWidth: 2)
            DialTicks()
                .stroke(CompassTheme.quietText, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            Needle()
                .fill(HolosTheme.highlight)
                .overlay {
                    Needle().stroke(HolosTheme.keyline, lineWidth: 1.5)
                }
                .rotationEffect(.degrees(angle))
                // Resting, not gone: the dial never looks broken.
                .opacity(target == nil ? 0.3 : 1)
            Circle()
                .fill(CompassTheme.text)
                .frame(width: 10, height: 10)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if let target { angle = target.degrees }
        }
        .onChange(of: target) { _, newTarget in
            turn(to: newTarget)
        }
        .accessibilityHidden(true)
    }

    private func turn(to newTarget: Direction?) {
        guard let newTarget else { return }
        let current = angle.truncatingRemainder(dividingBy: 360)
        let normalised = current < 0 ? current + 360 : current
        var delta = newTarget.degrees - normalised
        // The shortest way round: the scan always steps a quarter turn
        // clockwise, and a pointing head never sends the needle the long way.
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        if reduceMotion {
            angle += delta
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                angle += delta
            }
        }
    }
}

/// A slim diamond from the centre to the rim, pointing up.
private struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let width = radius * 0.16
        var path = Path()
        path.move(to: CGPoint(x: centre.x, y: centre.y - radius * 0.78))
        path.addLine(to: CGPoint(x: centre.x + width, y: centre.y))
        path.addLine(to: CGPoint(x: centre.x, y: centre.y + radius * 0.22))
        path.addLine(to: CGPoint(x: centre.x - width, y: centre.y))
        path.closeSubpath()
        return path
    }
}

/// Four short marks at north, east, south and west.
private struct DialTicks: Shape {
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let outer = radius * 0.92
        let inner = radius * 0.80
        var path = Path()
        for direction in Direction.allCases {
            let radians = direction.degrees * .pi / 180
            // Degrees run clockwise from straight up.
            let dx = CGFloat(sin(radians))
            let dy = CGFloat(-cos(radians))
            path.move(to: CGPoint(x: centre.x + dx * inner, y: centre.y + dy * inner))
            path.addLine(to: CGPoint(x: centre.x + dx * outer, y: centre.y + dy * outer))
        }
        return path
    }
}

#Preview("Needle") {
    HStack(spacing: 24) {
        NeedleDial(target: .north)
        NeedleDial(target: .east)
        NeedleDial(target: nil)
    }
    .frame(height: 140)
    .padding()
    .background(CompassTheme.background)
}
