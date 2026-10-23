import SwiftUI

/// Words in the room: the person's own (warm, with a speaker icon, because
/// they were spoken aloud) or the nurse's (white, text only — the voice
/// belongs to the person, so nobody else speaks through it).
struct SpeechBubble: View {
    enum Voice {
        case person
        case other
    }

    let text: Text
    let voice: Voice
    let width: CGFloat
    /// How far the box sits sideways from its tail, to stay inside the room.
    var shift: CGFloat = 0
    /// True when the bubble hangs below its speaker (near the top edge).
    var tailUp = false

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(spacing: -1) {
            if tailUp { tail }
            box
            if !tailUp { tail }
        }
    }

    private var fill: Color {
        voice == .person ? RoomTheme.voice : HolosTheme.paper
    }

    private var box: some View {
        HStack(alignment: .top, spacing: 8) {
            if voice == .person {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.headline)
                    .foregroundStyle(HolosTheme.ink.opacity(0.75))
                    .accessibilityHidden(true)
            }
            text
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(HolosTheme.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: width, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(HolosTheme.keyline.opacity(contrast == .increased ? 1 : 0.7), lineWidth: contrast == .increased ? 3 : 2)
        }
        .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
        .offset(x: shift)
    }

    private var tail: some View {
        Triangle(pointsUp: tailUp)
            .fill(fill)
            .frame(width: 22, height: 14)
    }
}

#Preview("Speech bubbles") {
    VStack(spacing: 30) {
        SpeechBubble(text: Text("I'm in pain."), voice: .person, width: 260)
        SpeechBubble(text: Text("How are you feeling?"), voice: .other, width: 260, shift: 40, tailUp: true)
    }
    .padding(40)
    .background(Color.teal)
}
