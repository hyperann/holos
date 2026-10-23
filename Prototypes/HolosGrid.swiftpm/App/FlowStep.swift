/// The judged tour, in order, then the free board it leads to.
enum FlowStep: Int, CaseIterable, Sendable {
    case problem
    case oneSwitch
    case aphasia
    case ukrainian
    case closing
    case free

    var isGuided: Bool { self == .oneSwitch || self == .aphasia }
}

/// Where a guided step is: reading its goal, working on the board, reading
/// what it achieved — and, after step 3 only, the optional head-turn panel.
enum FlowPhase: Sendable {
    case intro
    case working
    case done
    /// Core's `HeadTryPanel`, on its own after step 3's success card. It owns
    /// the switch while it is on screen.
    case headTry
}
