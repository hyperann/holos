import SwiftUI

/// The small "Next" tag on the cell the guide suggests.
///
/// Deliberately small and dark, so it never competes with the yellow scan
/// highlight: the highlight says "you are here", the tag says "go there".
/// The tag itself is hidden from VoiceOver, which hears the same suggestion
/// as the element's value instead — see `guideMarker(_:language:)`.
struct GuideMarker: View {
    @Environment(HolosSettings.self) private var settings

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
            Copy.nextTag.text(settings.language)
                .lineLimit(1)
        }
        .font(.system(.caption, design: .rounded, weight: .heavy))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(WordKind.describing.ink, in: Capsule())
        .overlay { Capsule().strokeBorder(Color.white, lineWidth: 2) }
        .fixedSize()
        .offset(x: 6, y: -12)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Puts the "Next" tag on this view while `isOn` — the picture only.
    /// For an element that already has an accessibility value of its own,
    /// which must then carry the suggestion itself.
    func guideMarker(_ isOn: Bool) -> some View {
        overlay(alignment: .topTrailing) {
            if isOn {
                GuideMarker()
            }
        }
    }

    /// The tag, and the same suggestion as this element's accessibility
    /// value, so a VoiceOver user hears "Next" where a sighted one sees it.
    /// Only for elements that set no value of their own: of two value
    /// modifiers only one is used, and the other would silently vanish.
    func guideMarker(_ isOn: Bool, language: Language) -> some View {
        guideMarker(isOn)
            .accessibilityValue(isOn ? Copy.nextTag.text(language) : Text(verbatim: ""))
    }
}

#Preview("Guide marker") {
    RoundedRectangle(cornerRadius: 18)
        .fill(WordKind.thing.tint)
        .frame(width: 160, height: 140)
        .guideMarker(true)
        .padding(40)
        .holos(.preview())
}
