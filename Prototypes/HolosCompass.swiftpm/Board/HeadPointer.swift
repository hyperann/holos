import Foundation
import Observation

/// Turns where the head is pointing into one of the four directions.
///
/// This is what four choices make possible. A head switch has to *scan*:
/// turn, wait for the light, turn again. With only four targets, each in
/// its own direction, the head can simply point at the one it wants — up,
/// right, down, left — and hold. For Oleksandr that means no light to wait
/// for: he points straight at what he wants and holds.
///
/// It reads the angles Core's `HeadSwitch` already measures from the
/// person's own resting position, and adds rules of its own:
/// - Only the dominant axis counts, beyond the same threshold the head
///   switch uses, so a diagonal glance lights nothing.
/// - A choice needs a full second of holding — longer than a switch press,
///   because a pointed choice may say something aloud.
/// - After a choice the head must come back to the middle before the next
///   one, so holding "up" says "Yes" once, not over and over.
/// - Below home, resting still in the middle steps back one level after
///   five scan steps' worth of time (seven seconds at the default speed).
///   That is the head-only way out, and it mirrors the scan's own rule
///   that two quiet loops step out of a group. It is deliberately not
///   quick: resting in the middle is also how a person thinks, and someone
///   reading four choices must not be bounced back mid-decision. Any
///   pointing starts the count again, and it never happens at home.
///
/// Pointing honours Settings' hold like every other switch: while the
/// Settings sheet is open nothing lights, fills or is chosen, and the head
/// must come back to the middle afterwards before anything can be.
@MainActor
@Observable
final class HeadPointer {
    private(set) var isOn = false
    /// The direction lit by the head right now, if any.
    private(set) var direction: Direction?
    /// 0…1 towards choosing `direction`. Drives the filling ring.
    private(set) var progress: Double = 0
    /// 0…1 towards stepping back by resting in the middle. Drives the ring
    /// on the Back chip.
    private(set) var restProgress: Double = 0
    /// Which way is "right" and "up" has not been verified on every device,
    /// so rather than guess, the person (or a carer) can flip either axis.
    var swapLeftRight = false
    var swapUpDown = false

    /// Called once per completed hold.
    @ObservationIgnored var onChoose: ((Direction) -> Void)?
    /// Called once each time a rest in the middle completes.
    @ObservationIgnored var onRestBack: (() -> Void)?
    /// Asked on every tick: may a rest in the middle step back right now?
    /// The board answers true only below home.
    @ObservationIgnored var restBackAllowed: () -> Bool = { false }
    @ObservationIgnored private var head: HeadSwitch?
    @ObservationIgnored private var hub: SwitchHub?
    @ObservationIgnored private var speaker: Speaker?
    @ObservationIgnored private var settings: HolosSettings?
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var armed = false
    @ObservationIgnored private var heldSince: Double?
    @ObservationIgnored private var restSince: Double?
    /// Whether turning pointing on is what switched the camera on. If the
    /// head switch was already on in Settings, turning pointing off must
    /// leave it on.
    @ObservationIgnored private var startedCamera = false

    static let dwellSeconds = 1.0
    /// A rest lasts this many scan steps, so a person who has slowed the
    /// scan down for themselves gets a longer rest too.
    static let restSteps = 5.0

    init() {}

    /// True while the head, not the scan, is choosing. Anything else —
    /// asking for the camera, no face, finding the centre — leaves the scan
    /// in charge, so a person is never left with nothing that works.
    var isPointing: Bool {
        guard isOn, let head else { return false }
        return head.status == .tracking && !head.isCalibrating
    }

    func turnOn(_ services: HolosServices) {
        guard !isOn else { return }
        head = services.hub.head
        hub = services.hub
        speaker = services.speaker
        settings = services.settings
        isOn = true
        // Wait for the head to rest in the middle before the first choice,
        // so turning pointing on while already looking aside chooses nothing.
        armed = false
        reset()
        resetRest()
        if !services.settings.headSwitchOn {
            startedCamera = true
            services.settings.headSwitchOn = true
        }
        let head = services.hub.head
        if !head.isRunning {
            Task { await head.enable() }
        }
        startLoop()
    }

    func turnOff() {
        guard isOn else { return }
        isOn = false
        loop?.cancel()
        loop = nil
        reset()
        resetRest()
        if startedCamera {
            startedCamera = false
            settings?.headSwitchOn = false
            head?.disable()
        }
    }

    // MARK: - Reading the head

    /// Polled rather than driven by camera frames: a head held perfectly
    /// still produces no new angles, but its hold still has to fill.
    private func startLoop() {
        loop?.cancel()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.tick()
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func tick() {
        // The head switch was turned off in Settings: follow it.
        if let settings, !settings.headSwitchOn {
            startedCamera = false
            turnOff()
            return
        }
        // Settings holds every switch while it is open, so a carer testing
        // the head there never chooses a petal on the board underneath.
        // Disarmed, so the head must come back to the middle afterwards.
        if let hub, hub.isSuspended {
            armed = false
            reset()
            resetRest()
            return
        }
        guard isPointing, let head else {
            reset()
            resetRest()
            return
        }
        let threshold = (settings?.headTurnDegrees ?? 18) * .pi / 180
        let x = head.yaw * (swapLeftRight ? -1 : 1)
        let y = head.pitch * (swapUpDown ? -1 : 1)
        let magnitude = max(abs(x), abs(y))
        let now = ProcessInfo.processInfo.systemUptime

        if magnitude < threshold * 0.5 {
            armed = true
            reset()
            rest(now)
            return
        }
        // Anything but resting — even a small movement that lights nothing —
        // starts the rest count again.
        resetRest()
        guard armed, magnitude >= threshold else {
            reset()
            return
        }

        let pointed: Direction
        if abs(x) >= abs(y) {
            pointed = x > 0 ? .east : .west
        } else {
            pointed = y > 0 ? .north : .south
        }

        guard pointed == direction, let start = heldSince else {
            // A new direction starts its own hold from nothing.
            direction = pointed
            heldSince = now
            progress = 0
            return
        }
        progress = min((now - start) / Self.dwellSeconds, 1)
        if progress >= 1 {
            armed = false
            reset()
            onChoose?(pointed)
        }
    }

    /// Counts a rest in the middle towards stepping back — only where the
    /// board allows it, and never while the person's words are being
    /// spoken, so a rest starts after the voice has finished.
    private func rest(_ now: Double) {
        guard restBackAllowed(), speaker?.isSpeaking != true else {
            resetRest()
            return
        }
        let start = restSince ?? now
        restSince = start
        let seconds = Self.restSteps * (settings?.scanInterval ?? 1.4)
        let fraction = min((now - start) / max(seconds, 1), 1)
        if fraction != restProgress { restProgress = fraction }
        if fraction >= 1 {
            resetRest()
            onRestBack?()
        }
    }

    /// Clears the lit direction, writing only what changed: this runs
    /// twenty times a second, and every write redraws the board.
    private func reset() {
        if direction != nil { direction = nil }
        if progress != 0 { progress = 0 }
        heldSince = nil
    }

    private func resetRest() {
        if restProgress != 0 { restProgress = 0 }
        restSince = nil
    }
}
