import Observation
import SwiftUI

/// The parts of the judged flow, in order, and the free board after it.
enum FlowStep: Int, CaseIterable, Identifiable, Sendable {
    case problem
    case compose
    case headPoint
    case ukrainian
    case closing
    case free

    var id: Int { rawValue }

    /// "Step n of 4" — the closing card belongs to step 4.
    var number: Int? {
        switch self {
        case .problem: 1
        case .compose: 2
        case .headPoint: 3
        case .ukrainian, .closing: 4
        case .free: nil
        }
    }

    var title: Bilingual {
        switch self {
        case .problem: Copy.Steps.problem
        case .compose: Copy.Steps.compose
        case .headPoint: Copy.Steps.head
        case .ukrainian: Copy.Steps.ukrainian
        case .closing: Copy.Steps.closing
        case .free: Copy.Steps.free
        }
    }

    var next: FlowStep {
        switch self {
        case .problem: .compose
        case .compose: .headPoint
        case .headPoint: .ukrainian
        case .ukrainian: .closing
        case .closing, .free: .free
        }
    }
}

/// Where the person is in the experience.
///
/// Steps are deliberately dumb: each one finishes by calling `advance(from:)`,
/// and only this type knows what comes next. It also owns the one
/// `HeadPointer`, so a swapped left and right set in step 3 is still
/// swapped on the free board.
@MainActor
@Observable
final class Experience {
    private(set) var step: FlowStep
    let pointer: HeadPointer

    init(start: FlowStep = .problem) {
        step = start
        pointer = HeadPointer()
    }

    /// Moves on from `current` — and only if `current` is still the step on
    /// screen. A fading screen's button, or a timer that fires just as the
    /// person presses, can then never skip a whole step.
    func advance(from current: FlowStep) {
        guard step == current else { return }
        go(to: current.next)
    }

    func restart() {
        go(to: .problem)
    }

    func keepTalking() {
        go(to: .free)
    }

    private func go(to next: FlowStep) {
        // A cross-fade: no movement, so nothing changes under Reduce Motion.
        withAnimation(.easeInOut(duration: 0.35)) {
            step = next
        }
    }
}
