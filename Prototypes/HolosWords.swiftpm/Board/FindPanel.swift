import SwiftUI

/// One screen of Find a word: the path so far, one question, a few big
/// answers, and Back.
///
/// The person never has to produce the word — only to say what kind of
/// thing it is, then recognise it among two to four pictures. Each
/// candidate shows its first letter ("Д…"): a written first-letter cue,
/// the printed cousin of the first-sound cue therapists give aloud
/// (speaking it is future work). It also shows the sentence it would make,
/// so someone who can read confirms the meaning before choosing.
struct FindPanel: View {
    let screen: FindCategory
    var isScanning = false
    /// Answers per row: one row on a wide iPad, two or three elsewhere.
    var perRow = 3

    @Environment(Experience.self) private var experience
    @Environment(HolosSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var contrast

    private var board: WordsBoard { experience.board }

    /// Back is a real button here, for touch users too: it is the only way
    /// out of Find a word.
    private enum Slot: Identifiable {
        case option(FindOption)
        case back

        var id: String {
            switch self {
            case .option(let option): option.id
            case .back: "back"
            }
        }
    }

    var body: some View {
        let language = settings.language
        let gender = settings.gender
        VStack(alignment: .leading, spacing: 12) {
            taggedText(breadcrumb, language)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(WordsTheme.secondary(contrast))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityLabel(breadcrumbLabel)
            screen.question.text(language, gender)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(HolosTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 12) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 12) {
                        ForEach(row) { slot in
                            cell(slot)
                        }
                        // Keeps a short last row's cells the same size as the rest.
                        ForEach(0..<max(perRow - row.count, 0), id: \.self) { _ in
                            Color.clear
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(WordKind.question.ink.opacity(contrast == .increased ? 1 : 0.35), lineWidth: 1.5)
        }
    }

    // MARK: - Layout

    private var slots: [Slot] {
        screen.options.map { Slot.option($0) } + [Slot.back]
    }

    private var rows: [[Slot]] {
        let size = max(perRow, 1)
        let all = slots
        return stride(from: 0, to: all.count, by: size).map { start in
            Array(all[start..<min(start + size, all.count)])
        }
    }

    /// "Find a word › A person › Family" — where the person is in the tree.
    private var breadcrumb: String {
        board.trail.map { $0.label(settings.language, settings.gender) }.joined(separator: " › ")
    }

    private var breadcrumbLabel: Text {
        Bilingual.joined(board.trail.map(\.label), separator: ", ").text(settings.language, settings.gender)
    }

    // MARK: - Cells

    @ViewBuilder
    private func cell(_ slot: Slot) -> some View {
        switch slot {
        case .back:
            BackCell(isHighlighted: board.scanner.isHighlighted(ScanID.findBack)) {
                board.tap(ScanID.findBack)
            }
            .guideMarker(board.target == .findBack, language: settings.language)
            .accessibilityHint(Copy.findBackHint.text(settings.language))
        case .option(let option):
            let id = ScanID.findOption(option)
            switch option {
            case .category(let category):
                categoryCell(category, id: id)
            case .word(let concept, let home):
                wordCell(concept: concept, home: home, id: id)
            }
        }
    }

    private func categoryCell(_ category: FindCategory, id: String) -> some View {
        let language = settings.language
        let gender = settings.gender
        return Button {
            board.tap(id)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: category.symbol)
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(category.kind.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 12)
                    .accessibilityHidden(true)
                category.label.text(language, gender)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(category.kind.tint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(category.kind.ink.opacity(contrast == .increased ? 1 : 0.35), lineWidth: contrast == .increased ? 3 : 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .scanHighlight(board.scanner.isHighlighted(id), cornerRadius: 20)
        .guideMarker(board.target == .findOption(id), language: language)
        .accessibilityLabel(category.label.text(language, gender))
        .accessibilityHint(Copy.categoryHint.text(language))
        .accessibilityInputLabels(category.label.inputLabels)
    }

    @ViewBuilder
    private func wordCell(concept: String, home: FrameID, id: String) -> some View {
        let language = settings.language
        let gender = settings.gender
        if let found = board.resolved(concept, home: home) {
            let phrase = found.phrase
            let word = phrase.label(language, gender)
            let cue = String(word.prefix(1)).uppercased() + "…"
            let isNext = board.target == .findOption(id)
            let cueValue = Copy.startsWith(String(word.prefix(1)))
            // One value for both: of two value modifiers only one is used.
            let value = isNext ? Bilingual.joined([cueValue, Copy.nextTag], separator: ", ") : cueValue
            Button {
                board.tap(id)
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: phrase.symbol)
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(phrase.kind.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 12)
                        .accessibilityHidden(true)
                    phrase.label.text(language, gender)
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(HolosTheme.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                    phrase.speech.text(language, gender)
                        .font(.system(.footnote, design: .serif))
                        .foregroundStyle(WordsTheme.secondary(contrast))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(phrase.kind.tint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .topLeading) {
                    taggedText(cue, language)
                        .font(.system(.title3, design: .serif, weight: .heavy))
                        .foregroundStyle(HolosTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white, in: Capsule())
                        .overlay { Capsule().strokeBorder(phrase.kind.ink, lineWidth: 1.5) }
                        .padding(8)
                        .accessibilityHidden(true)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(phrase.kind.ink.opacity(contrast == .increased ? 1 : 0.35), lineWidth: contrast == .increased ? 3 : 1.5)
                }
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .scanHighlight(board.scanner.isHighlighted(id), cornerRadius: 20)
            .guideMarker(isNext)
            .accessibilityLabel(phrase.label.text(language, gender))
            .accessibilityValue(value.text(language))
            .accessibilityHint(Copy.finishes(phrase.speech).text(language, gender))
            .accessibilityInputLabels(phrase.label.inputLabels)
        } else {
            // Every word in the tree has a sentence (see `FindTree`); this
            // keeps the scan and the screen in step even if one were missing.
            Button {
                board.tap(id)
            } label: {
                taggedText(concept, .english)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(HolosTheme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(WordKind.control.tint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .scanHighlight(board.scanner.isHighlighted(id), cornerRadius: 20)
        }
    }
}

#Preview("Find a word") {
    let services = HolosServices.preview()
    let experience = Experience()
    experience.board.connect(services)
    experience.board.tap(ScanID.findOpen)
    experience.board.tap(ScanID.findCategory(FindTree.person.id))
    experience.board.tap(ScanID.findCategory(FindTree.family.id))
    experience.board.tap(ScanID.findCategory(FindTree.sameAge.id))
    return Group {
        if let screen = experience.board.findScreen {
            FindPanel(screen: screen, isScanning: true, perRow: 5)
        }
    }
    .padding()
    .frame(height: 520)
    .background(WordsTheme.paper)
    .environment(experience)
    .holos(services)
}
