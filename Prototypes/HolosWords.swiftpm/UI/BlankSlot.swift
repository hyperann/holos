import SwiftUI

/// The blank in "Call my ____": the place the missing word goes.
///
/// It is the visual heart of the concept, so it is drawn as a real gap in
/// a real sentence rather than an empty text field. It pulses gently to
/// say "this is what we are looking for"; with Reduce Motion it stays
/// still. A `ghost` word can sit inside, blurred — the word that is "right
/// there" and still cannot be read.
struct BlankSlot: View {
    var width: CGFloat = 150
    var ghost: Bilingual?

    @Environment(HolosSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if let ghost {
                ghost.text(settings.language, settings.gender)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink.opacity(0.22))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .blur(radius: 6)
                    .padding(.bottom, 10)
            }
            Capsule()
                .fill(HolosTheme.ink)
                .frame(height: 5)
        }
        .frame(width: width, height: 52)
        .opacity(dim ? 0.3 : 1)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: dim)
        .onAppear { dim = !reduceMotion }
        .onChange(of: reduceMotion) { dim = !reduceMotion }
        .accessibilityHidden(true)
    }
}

#Preview("Blank") {
    HStack(alignment: .lastTextBaseline, spacing: 12) {
        Text(verbatim: "Call my")
            .font(.system(.largeTitle, design: .serif, weight: .bold))
        BlankSlot(width: 180, ghost: Copy.ghostWord)
    }
    .padding()
    .holos(.preview())
}
