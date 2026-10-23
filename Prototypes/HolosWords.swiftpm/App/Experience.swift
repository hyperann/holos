import Foundation
import Observation

/// The three-minute tour: which step is showing, and what the person said.
///
/// Steps are dumb about each other; they report "done" and this moves on.
/// It also owns the board, so the board's state survives between the two
/// board steps and into free use afterwards.
@MainActor
@Observable
final class Experience {
    enum Step: Int, CaseIterable, Sendable {
        case problem
        case twoChoices
        case findWord
        case headTry
        case ukrainian
        case closing
        /// After the tour: the board on its own, which is the real app.
        case free

        /// Which of the four judged parts this step belongs to, for "Step 2 of 4".
        var part: Int? {
            switch self {
            case .problem: 1
            case .twoChoices: 2
            case .findWord, .headTry: 3
            case .ukrainian: 4
            case .closing, .free: nil
            }
        }
    }

    private(set) var step: Step = .problem
    /// The message just spoken in a guided step, shown as the step's reward
    /// while the voice finishes.
    private(set) var justSaid: [Phrase]?
    /// Everything spoken during the tour, replayed in Ukrainian in step 4.
    private(set) var tourSentences: [Phrase] = []
    /// Drives the Settings sheet. Core's sheet holds switch presses itself
    /// while it is open, so nothing else needs to pause.
    var settingsOpen = false

    let board = WordsBoard()

    @ObservationIgnored private var holdTask: Task<Void, Never>?

    init() {
        board.onSpoke = { [weak self] phrases in
            self?.spoke(phrases)
        }
        board.onSkip = { [weak self] in
            self?.advance()
        }
    }

    /// The sentences step 4 plays: what the person really said, or the
    /// tour's own goals if they skipped before saying anything.
    var sentencesForUkrainian: [Phrase] {
        var seen = Set<String>()
        let source = tourSentences.isEmpty ? Vocabulary.tourExample : tourSentences
        return Array(source.filter { seen.insert($0.id).inserted }.prefix(4))
    }

    func advance() {
        holdTask?.cancel()
        holdTask = nil
        justSaid = nil
        switch step {
        case .problem: show(.twoChoices)
        case .twoChoices: show(.findWord)
        case .findWord: show(.headTry)
        case .headTry: show(.ukrainian)
        case .ukrainian: show(.closing)
        case .closing: show(.free)
        case .free: break
        }
    }

    func restart() {
        holdTask?.cancel()
        holdTask = nil
        justSaid = nil
        tourSentences = []
        show(.problem)
    }

    func keepTalking() {
        holdTask?.cancel()
        holdTask = nil
        justSaid = nil
        show(.free)
    }

    /// Jumps straight to a step. The tour moves through it; previews use it
    /// to open on any step.
    func show(_ next: Step) {
        step = next
        switch next {
        case .twoChoices: board.begin(goal: .feelPainNeedMedicine)
        case .findWord: board.begin(goal: .callWife)
        case .free: board.begin(goal: nil)
        case .problem, .headTry, .ukrainian, .closing: break
        }
    }

    /// Any spoken message completes a guided step — not only the goal.
    /// Someone who says something else has still said something, and the
    /// tour should never hold them hostage to the script.
    private func spoke(_ phrases: [Phrase]) {
        guard step == .twoChoices || step == .findWord, justSaid == nil else { return }
        tourSentences += phrases
        justSaid = phrases
        holdTask?.cancel()
        holdTask = Task { [weak self] in
            // Let the voice finish first: the person's own sentence is the
            // reward, and the next step must not talk over it.
            try? await Task.sleep(for: .seconds(0.8))
            for _ in 0..<50 {
                guard !Task.isCancelled, let self else { return }
                if !self.board.isVoiceBusy { break }
                try? await Task.sleep(for: .seconds(0.2))
            }
            try? await Task.sleep(for: .seconds(1.0))
            // Never move the tour on underneath an open Settings sheet.
            while !Task.isCancelled, self?.settingsOpen == true {
                try? await Task.sleep(for: .seconds(0.3))
            }
            guard !Task.isCancelled else { return }
            self?.advance()
        }
    }
}
