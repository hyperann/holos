import AVFoundation
import ImageIO
import Vision

/// One reading of where the face is pointing.
struct HeadSample: Sendable {
    let faceFound: Bool
    /// Radians. The sign says which way; the head switch only uses the size.
    let yaw: Double
    let pitch: Double
}

/// Owns the front camera and Vision, and reports head angles.
///
/// Everything below runs on one private serial queue — session setup, the
/// frame callback, the Vision request — which is what the
/// `@unchecked Sendable` promises: no stored state is ever touched from
/// two threads. Frames are read and dropped; nothing is recorded, saved
/// or sent anywhere.
final class HeadTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let queue = DispatchQueue(label: "holos.head-tracker", qos: .userInitiated)
    private let session = AVCaptureSession()
    private let onSample: @Sendable (HeadSample) -> Void

    // Queue-confined state.
    private var configured = false
    private var frameIndex = 0
    private var framesWithoutFace = 0
    private var orientationIndex = 0
    /// The orientation that last found a face, once one has.
    private var lastGoodIndex: Int?

    /// The ways the camera image can be turned relative to the face.
    ///
    /// Front cameras sit on different edges of different iPads (and a Mac's
    /// sits above the screen), so the right orientation cannot be known in
    /// advance. The tracker starts from a guess and, if it sees no face for
    /// about a second, tries the next quarter-turn. Yaw is measured
    /// relative to the face itself, so the reading is the same whichever
    /// orientation finds it.
    ///
    /// Once an orientation has worked it is trusted through short losses —
    /// a big deliberate turn, a cup raised to drink — and only questioned
    /// after three seconds, and even then it gets every other try, so a
    /// returning face is caught within about a second.
    private static let orientations: [CGImagePropertyOrientation] = [
        .leftMirrored, .upMirrored, .rightMirrored, .downMirrored,
    ]

    init(onSample: @escaping @Sendable (HeadSample) -> Void) {
        self.onSample = onSample
        super.init()
    }

    /// Opens the camera and starts reading frames. `completion` reports
    /// false when there is no usable camera.
    func start(initialGuess: CGImagePropertyOrientation, completion: @escaping @Sendable (Bool) -> Void) {
        queue.async {
            if let index = Self.orientations.firstIndex(of: initialGuess) {
                self.orientationIndex = index
            }
            let ready = self.configureIfNeeded()
            if ready, !self.session.isRunning {
                self.session.startRunning()
            }
            completion(ready)
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureIfNeeded() -> Bool {
        if configured { return true }
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video)
        guard let camera, let input = try? AVCaptureDeviceInput(device: camera) else { return false }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        // A small frame is plenty to find one face, and costs far less battery.
        if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        }
        guard session.canAddInput(input) else { return false }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else { return false }
        session.addOutput(output)
        configured = true
        return true
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameIndex &+= 1
        // Every other frame is plenty for a deliberate, held turn.
        guard frameIndex % 2 == 0, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        // Revision 3 reports yaw and pitch as continuous angles rather than
        // in 45° steps, which is what makes a modest turn measurable.
        request.revision = VNDetectFaceRectanglesRequestRevision3
        let orientation = Self.orientations[orientationIndex % Self.orientations.count]
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return
        }

        // The largest face is the person using the device, not a visitor
        // walking past behind them.
        let face = request.results?.max { lhs, rhs in
            lhs.boundingBox.width * lhs.boundingBox.height < rhs.boundingBox.width * rhs.boundingBox.height
        }
        if let face, let yaw = face.yaw?.doubleValue {
            framesWithoutFace = 0
            lastGoodIndex = orientationIndex % Self.orientations.count
            onSample(HeadSample(faceFound: true, yaw: yaw, pitch: face.pitch?.doubleValue ?? 0))
        } else {
            framesWithoutFace += 1
            chooseNextOrientation()
            onSample(HeadSample(faceFound: false, yaw: 0, pitch: 0))
        }
    }

    /// About 15 processed frames is one second.
    private func chooseNextOrientation() {
        let count = Self.orientations.count
        guard let good = lastGoodIndex else {
            // Never seen a face yet: try each quarter-turn for a second.
            if framesWithoutFace % 15 == 0 {
                orientationIndex = (orientationIndex + 1) % count
            }
            return
        }
        // Keep the one that worked for three seconds…
        guard framesWithoutFace > 45 else {
            orientationIndex = good
            return
        }
        // …then alternate: a second on another orientation, a second back
        // on the good one, in case the device itself was turned.
        let slot = (framesWithoutFace - 46) / 15
        if slot % 2 == 1 {
            orientationIndex = good
        } else {
            orientationIndex = (good + 1 + (slot / 2) % (count - 1)) % count
        }
    }
}
