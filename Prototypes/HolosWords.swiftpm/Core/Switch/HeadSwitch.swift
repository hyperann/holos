import AVFoundation
import ImageIO
import Observation
import UIKit

/// A deliberate head turn, held briefly, as a switch.
///
/// For someone in early rehabilitation who can move their head but not
/// their hands, this is the whole interface. Three rules keep it from
/// pressing by accident:
/// - The turn must pass a threshold (settings: degrees), so ordinary
///   looking around does not count.
/// - It must be *held* (settings: seconds), so a glance at a visitor does
///   not count either.
/// - After a press, the head must come back towards the centre before the
///   next one can start, so one long turn is one press, not a stream.
///
/// Angles are measured from the person's own resting position, not from
/// the camera: an iPad on a bed mount off to one side sees a resting head
/// already turned, and without a centre of its own the switch would either
/// press by itself or never re-arm. The centre is found when tracking
/// starts (and again with `recenter()`) from a moment of holding still.
///
/// It is optional and always has a way out: if the camera is refused, or
/// no face is found, the status says so and every other switch still works.
@MainActor
@Observable
final class HeadSwitch {
    enum Status: Equatable, Sendable {
        /// Not running.
        case off
        /// Waiting for the person to answer the camera permission prompt.
        case asking
        /// Camera permission was refused (it can be changed in Settings).
        case denied
        /// No usable camera on this device.
        case noCamera
        /// Running, but no face in view.
        case searching
        /// Running and following a face.
        case tracking
    }

    private(set) var status: Status = .off
    /// 0…1: how far the current turn is towards a press. Drives the meter.
    private(set) var progress: Double = 0
    /// The latest yaw (left–right turn) in radians from the person's own
    /// centre — exactly what the switch measures — for an on-screen level.
    private(set) var yaw: Double = 0
    /// The latest pitch (up–down nod) in radians from the person's centre.
    /// The switch itself only uses yaw; pitch is here for boards that let
    /// the head *point*.
    private(set) var pitch: Double = 0
    /// True while the switch is finding the person's resting position.
    /// Nothing can press during it; the meter asks them to hold still.
    private(set) var isCalibrating = false

    @ObservationIgnored var onTrigger: (() -> Void)?
    @ObservationIgnored private let settings: HolosSettings
    @ObservationIgnored private var tracker: HeadTracker?
    @ObservationIgnored private var turnStartedAt: Double?
    @ObservationIgnored private var armed = true
    @ObservationIgnored private var lastFaceAt: Double = 0
    @ObservationIgnored private var neutralYaw: Double = 0
    @ObservationIgnored private var neutralPitch: Double = 0
    @ObservationIgnored private var calibrationSamples: [HeadSample] = []
    /// Every face sample since this calibration began, steady or not.
    @ObservationIgnored private var calibrationSeen = 0
    /// True for a centre the person asked for with `recenter()`: whatever
    /// steady position they hold is the one they mean, however far off-axis.
    @ObservationIgnored private var calibrationIsExplicit = false
    /// The steadiest window seen so far, used if the time limit runs out.
    @ObservationIgnored private var bestWindow: (spread: Double, yaw: Double, pitch: Double)?

    /// Samples in one window: about two thirds of a second of video.
    private static let calibrationCount = 10
    /// After about three seconds a centre is accepted anyway, so that a head
    /// tremor or a restless moment can never leave the switch stuck in
    /// "hold still" for good.
    private static let calibrationLimit = 45

    init(settings: HolosSettings) {
        self.settings = settings
    }

    var isRunning: Bool { status == .searching || status == .tracking }

    /// Asks for the camera if needed, then starts tracking.
    func enable() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            status = .asking
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                status = .denied
                return
            }
        default:
            status = .denied
            return
        }

        let tracker = self.tracker ?? HeadTracker { [weak self] sample in
            Task { @MainActor in self?.handle(sample) }
        }
        self.tracker = tracker
        status = .searching
        progress = 0
        beginCalibration(explicit: false)
        lastFaceAt = ProcessInfo.processInfo.systemUptime
        tracker.start(initialGuess: Self.orientationGuess()) { [weak self] ready in
            Task { @MainActor in
                if !ready { self?.status = .noCamera }
            }
        }
    }

    func disable() {
        tracker?.stop()
        status = .off
        progress = 0
        turnStartedAt = nil
        isCalibrating = false
        calibrationSamples.removeAll()
        bestWindow = nil
    }

    /// Finds the person's resting position again — after the device or the
    /// bed has moved. They hold still for a moment; nothing presses meanwhile.
    func recenter() {
        guard isRunning else { return }
        beginCalibration(explicit: true)
    }

    private func beginCalibration(explicit: Bool) {
        isCalibrating = true
        calibrationIsExplicit = explicit
        calibrationSamples.removeAll()
        calibrationSeen = 0
        bestWindow = nil
        armed = false
        turnStartedAt = nil
        progress = 0
    }

    /// Takes the median of a steady run of samples as the centre.
    ///
    /// - Steady means the middle eight of ten samples lie within a few
    ///   degrees — trimmed, so one jittery frame cannot spoil a window, and
    ///   never tighter than 4°, so a mild tremor still calibrates.
    /// - An automatic centre (when tracking starts, or after a long absence)
    ///   prefers a window facing roughly towards the camera. Without that,
    ///   someone already holding a turn — exactly what the "try a head turn"
    ///   instructions invite — would have the turn taken as their centre,
    ///   and the switch would work backwards. An off-axis mount still works:
    ///   after the time limit the steadiest window is accepted wherever it is.
    /// - A centre asked for with `recenter()` accepts any steady position.
    private func calibrate(with sample: HeadSample) {
        calibrationSeen += 1
        calibrationSamples.append(sample)
        if calibrationSamples.count > Self.calibrationCount {
            calibrationSamples.removeFirst()
        }
        guard calibrationSamples.count == Self.calibrationCount else { return }

        let yaws = calibrationSamples.map(\.yaw).sorted()
        let pitches = calibrationSamples.map(\.pitch).sorted()
        let middle = Self.calibrationCount / 2
        let spread = yaws[Self.calibrationCount - 2] - yaws[1]
        let medianYaw = yaws[middle]
        let medianPitch = pitches[middle]
        let threshold = settings.headTurnDegrees * .pi / 180
        let tolerance = max(threshold / 4, 4 * .pi / 180)

        if spread < (bestWindow?.spread ?? .infinity) {
            bestWindow = (spread, medianYaw, medianPitch)
        }
        let steady = spread < tolerance
        let facingCamera = abs(medianYaw) < threshold / 2
        if steady, calibrationIsExplicit || facingCamera {
            finishCalibration(yaw: medianYaw, pitch: medianPitch)
        } else if calibrationSeen >= Self.calibrationLimit, let bestWindow {
            finishCalibration(yaw: bestWindow.yaw, pitch: bestWindow.pitch)
        }
    }

    private func finishCalibration(yaw centreYaw: Double, pitch centrePitch: Double) {
        neutralYaw = centreYaw
        neutralPitch = centrePitch
        calibrationSamples.removeAll()
        bestWindow = nil
        isCalibrating = false
        // At rest, so ready for the first press straight away.
        armed = true
        yaw = 0
        pitch = 0
    }

    private func handle(_ sample: HeadSample) {
        // Frames still in flight after `disable()` must not revive the meter.
        guard isRunning else { return }
        let now = ProcessInfo.processInfo.systemUptime

        guard sample.faceFound else {
            // A dropped frame or two is normal; only a full second without a
            // face is worth telling the person about.
            if now - lastFaceAt > 1.0 {
                status = .searching
                progress = 0
                turnStartedAt = nil
            }
            return
        }
        // After a long absence the person may have moved, so the old centre
        // is not trusted. A short loss keeps it: the face is often lost in
        // the middle of a big deliberate turn, and a centre taken then
        // would land on the turn.
        if now - lastFaceAt > 5, !isCalibrating {
            beginCalibration(explicit: false)
        }
        lastFaceAt = now
        status = .tracking
        if isCalibrating {
            calibrate(with: sample)
            return
        }
        yaw = sample.yaw - neutralYaw
        pitch = sample.pitch - neutralPitch

        let threshold = settings.headTurnDegrees * .pi / 180
        let magnitude = abs(yaw)
        if magnitude < threshold * 0.5 {
            // Back near the centre: ready for the next press.
            armed = true
            turnStartedAt = nil
            progress = 0
            return
        }
        guard armed, magnitude >= threshold else {
            turnStartedAt = nil
            progress = 0
            return
        }
        let start = turnStartedAt ?? now
        turnStartedAt = start
        progress = min((now - start) / max(settings.headHoldSeconds, 0.05), 1)
        if progress >= 1 {
            armed = false
            turnStartedAt = nil
            progress = 0
            onTrigger?()
        }
    }

    /// A first guess at how the front camera's image is turned, from the
    /// interface orientation. The tracker corrects a wrong guess by itself.
    private static func orientationGuess() -> CGImagePropertyOrientation {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let orientation = scene?.interfaceOrientation ?? .portrait
        switch orientation {
        case .landscapeLeft: return .upMirrored
        case .landscapeRight: return .downMirrored
        case .portraitUpsideDown: return .rightMirrored
        default: return .leftMirrored
        }
    }
}
