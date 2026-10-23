import SwiftUI

/// One tap between English and Ukrainian.
///
/// Both names are always visible, the current one filled, so a person who
/// reads only one of the two scripts can still find their language.
struct LanguageToggle: View {
    var isHighlighted = false

    @Environment(HolosSettings.self) private var settings
    @Environment(Feedback.self) private var feedback

    var body: some View {
        Button {
            settings.language = settings.language.other
            feedback.select()
        } label: {
            HStack(spacing: 0) {
                ForEach(Language.allCases) { language in
                    taggedText(language.shortName, language)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(language == settings.language ? Color.white : HolosTheme.ink)
                        .background(language == settings.language ? HolosTheme.ink : Color.clear, in: Capsule())
                }
            }
            .padding(4)
            .background(HolosTheme.paper, in: Capsule())
            .overlay { Capsule().strokeBorder(HolosTheme.ink, lineWidth: 2) }
        }
        .buttonStyle(.plain)
        .scanHighlight(isHighlighted, cornerRadius: 30)
        .accessibilityLabel(CoreCopy.languageLabel.text(settings.language))
        .accessibilityValue(taggedText(settings.language.nativeName, settings.language))
        .accessibilityHint(CoreCopy.languageHint.text(settings.language))
        .accessibilityInputLabels(CoreCopy.languageLabel.inputLabels)
    }
}

/// Explains, in the board's own language, that there is no Ukrainian
/// voice yet and how to add one. Shown only while it matters.
struct VoiceNotice: View {
    @Environment(HolosSettings.self) private var settings
    @Environment(Speaker.self) private var speaker
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if settings.language == .ukrainian, !speaker.hasUkrainianVoice {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "speaker.slash.fill")
                        .font(.title2)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        CoreCopy.noUkrainianVoiceTitle.text(settings.language)
                            .font(.headline)
                        CoreCopy.noUkrainianVoiceBody.text(settings.language)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(HolosTheme.ink)
                .padding(14)
                .background(WordKind.people.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
        // Coming back from Settings with a freshly downloaded voice should
        // clear the notice without a relaunch.
        .onChange(of: scenePhase) {
            if scenePhase == .active { speaker.refreshVoices() }
        }
    }
}

#Preview("Language") {
    let services = HolosServices.preview()
    VStack(spacing: 20) {
        LanguageToggle(isHighlighted: true)
        VoiceNotice()
    }
    .padding()
    .holos(services)
}
