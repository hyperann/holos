import SwiftUI

/// The sentence, written large like a line in a notebook, with its blank.
///
/// Finished sentences sit above; the one being built sits below as its
/// starter and a gap — "Call my ____" — so the person always sees what the
/// missing word has to do. Speak, Delete and Clear sit at the end of the
/// row, as in Core's message bar. When scanned, Clear opens on "No, keep
/// it", so a double press keeps the message; only "Yes, clear all" clears.
struct SentenceBar: View {
    var isScanning = false
    var compact = false

    @Environment(Experience.self) private var experience
    @Environment(MessageBuilder.self) private var message
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var board: WordsBoard { experience.board }

    var body: some View {
        let layout = compact
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        layout {
            sentence
            controls
        }
        .scanRow(ScanID.sentenceRow, scanner: board.scanner)
    }

    // MARK: - The sentence

    private var sentence: some View {
        let language = settings.language
        let gender = settings.gender
        return VStack(alignment: .leading, spacing: 6) {
            if !message.isEmpty {
                message.words.text(language, gender)
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(HolosTheme.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
            }
            if board.showsBlank {
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    board.frame.stem.text(language, gender)
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(HolosTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    BlankSlot(width: compact ? 90 : 150)
                }
            } else if message.isEmpty {
                Copy.sentencePlaceholder.text(language)
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(WordsTheme.secondary(contrast))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(.leading, 22)
        .padding(.vertical, 8)
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .overlay(alignment: .leading) {
                    // The notebook's red margin line.
                    Rectangle()
                        .fill(WordsTheme.margin.opacity(contrast == .increased ? 0.9 : 0.5))
                        .frame(width: 2)
                        .padding(.leading, 12)
                        .padding(.vertical, 6)
                }
                .overlay {
                    // The new sentence lands with a brief warm glow: the
                    // visual third of the select haptic and click. Driven by
                    // the count itself so every landing restarts it; a fade,
                    // so fine under Reduce Motion.
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(HolosTheme.highlight)
                        .keyframeAnimator(initialValue: 0.0, trigger: board.addedCount) { glow, opacity in
                            glow.opacity(opacity)
                        } keyframes: { _ in
                            KeyframeTrack {
                                LinearKeyframe(0.55, duration: 0.06)
                                LinearKeyframe(0.0, duration: 0.8)
                            }
                        }
                        .allowsHitTesting(false)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.sentenceRow.text(language))
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: Text {
        let language = settings.language
        let gender = settings.gender
        var parts: [Bilingual] = []
        if !message.isEmpty {
            parts.append(message.words)
        }
        if board.showsBlank {
            parts.append(Copy.withBlank(board.frame.stem))
        }
        if parts.isEmpty {
            parts.append(Copy.sentencePlaceholder)
        }
        return Bilingual.joined(parts).text(language, gender)
    }

    // MARK: - Speak, Delete, Clear

    private var controls: some View {
        let scanner = board.scanner
        // Only ever true while scanning: a stopped scan is inside nothing,
        // so touch users always see a single Clear that clears on a tap.
        let clearEntered = scanner.isEntered(ScanID.clear)
        return HStack(spacing: 10) {
            control(
                id: ScanID.speak,
                lit: scanner.isHighlighted(ScanID.speak),
                symbol: "speaker.wave.2.fill",
                words: CoreCopy.speak,
                hint: CoreCopy.speakHint,
                prominent: true
            )
            .guideMarker(board.target == .speak, language: settings.language)
            control(
                id: ScanID.delete,
                lit: scanner.isHighlighted(ScanID.delete),
                symbol: "delete.left.fill",
                words: CoreCopy.deleteLast,
                hint: Copy.deleteHint
            )
            if clearEntered {
                // Lit first inside Clear, as in Core's message bar.
                control(
                    id: ScanID.clearCancel,
                    lit: scanner.isHighlighted(ScanID.clearCancel),
                    symbol: "arrow.uturn.backward",
                    words: CoreCopy.clearCancel,
                    hint: Copy.clearCancelHint
                )
            }
            control(
                id: ScanID.clearConfirm,
                lit: scanner.isHighlighted(ScanID.clear) || scanner.isHighlighted(ScanID.clearConfirm),
                symbol: clearEntered ? "checkmark.circle.fill" : "xmark",
                words: clearEntered ? CoreCopy.clearConfirm : CoreCopy.clear,
                hint: Copy.clearHint
            )
            if isScanning {
                // Inside Clear, this is Clear's own way out; otherwise the row's.
                let backID = Scanner.backID(for: clearEntered ? ScanID.clear : ScanID.sentenceRow)
                BackPill(isHighlighted: scanner.isHighlighted(backID))
                    .frame(width: compact ? 64 : 80, height: 64)
            }
        }
        .frame(maxWidth: compact ? CGFloat.infinity : nil, alignment: .leading)
    }

    private func control(
        id: String,
        lit: Bool,
        symbol: String,
        words: Bilingual,
        hint: Bilingual,
        prominent: Bool = false
    ) -> some View {
        let language = settings.language
        return Button {
            board.tap(id)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                    .accessibilityHidden(true)
                words.text(language)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(prominent ? Color.white : HolosTheme.ink)
            .padding(.horizontal, 4)
            .frame(maxWidth: compact ? CGFloat.infinity : 88, minHeight: 64)
            .background(prominent ? HolosTheme.ink : WordKind.control.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(lit, cornerRadius: 16)
        .accessibilityLabel(words.text(language))
        .accessibilityHint(hint.text(language))
        .accessibilityInputLabels(words.inputLabels)
        // Fixed-size controls cannot grow with the largest text sizes; the
        // Large Content Viewer shows them instead.
        .accessibilityShowsLargeContentViewer {
            Label {
                words.text(language)
            } icon: {
                Image(systemName: symbol)
            }
        }
    }
}

#Preview("Sentence bar") {
    let services = HolosServices.preview()
    let experience = Experience()
    experience.board.connect(services)
    if let pain = Vocabulary.phrase(id: Phrase.makeID(.feel, "pain")) {
        services.message.add(pain)
    }
    return VStack(spacing: 20) {
        SentenceBar(isScanning: true)
        SentenceBar(isScanning: false, compact: true)
            .frame(width: 380)
    }
    .padding()
    .background(WordsTheme.paper)
    .environment(experience)
    .holos(services)
}
