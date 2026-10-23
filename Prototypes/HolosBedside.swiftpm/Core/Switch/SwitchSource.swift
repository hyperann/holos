/// Every way a person can press "the switch".
///
/// The whole app is built on one idea: every input becomes the same press,
/// and one scanner turns presses into speech. A new input — a sip-and-puff
/// tube, a blink, a foot pedal — only has to produce a `SwitchSource` and
/// it works everywhere at once, without touching what already works.
enum SwitchSource: String, CaseIterable, Identifiable, Sendable {
    /// The whole screen is the switch.
    case tap
    /// Space or Enter — what most commercial switch interfaces send.
    case key
    /// Any button on a game controller, including adaptive controllers.
    case controller
    /// A deliberate head turn, held briefly, seen by the front camera.
    case head

    var id: String { rawValue }
}
