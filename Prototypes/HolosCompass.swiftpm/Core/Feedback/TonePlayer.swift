import AVFoundation

/// Short synthesised sounds behind `FeedbackEvent`s.
///
/// Every sound is generated in code at launch, so the bundle ships no
/// audio files and nothing needs a licence. The voicing technique — a
/// pitch with a real attack, a few partials and a touch of filtered noise —
/// is adapted from Vidkryto's AudioDirector.
///
/// The sounds are quiet and low on purpose: they sit under a spoken
/// message, never on top of it.
@MainActor
final class TonePlayer {
    private var engine = AVAudioEngine()
    /// A small pool, so a select that lands right after a step does not
    /// cut the step's tail off.
    private var nodes: [AVAudioPlayerNode] = (0..<3).map { _ in AVAudioPlayerNode() }
    private var nextNode = 0
    private var isWired = false
    private let format: AVAudioFormat?
    private var buffers: [FeedbackEvent: AVAudioPCMBuffer] = [:]

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        guard let format else { return }
        // Typed up front: seven nested literals are a lot to ask the type
        // checker to infer on its own.
        let rendered: [FeedbackEvent: AVAudioPCMBuffer?] = [
            // A dry wooden tick, the sound of a bead moving on a string.
            .step: Self.render(format: format, duration: 0.05, layers: [
                Layer(duration: 0.02, noise: 1, brightness: 0.8, attack: 0.0008, decay: 9, volume: 0.12),
                Layer(duration: 0.04, pitch: 1320, decay: 10, volume: 0.06),
            ]),
            // Two rising notes: in.
            .enter: Self.render(format: format, duration: 0.2, layers: [
                Layer(duration: 0.08, pitch: 523.25, partials: [1, 0.2], attack: 0.003, decay: 6, volume: 0.16),
                Layer(start: 0.08, duration: 0.11, pitch: 659.25, partials: [1, 0.2], attack: 0.003, decay: 6, volume: 0.17),
            ]),
            // A bright, warm confirmation with a little body.
            .select: Self.render(format: format, duration: 0.28, layers: [
                Layer(duration: 0.025, noise: 1, brightness: 0.9, attack: 0.0005, decay: 10, volume: 0.15),
                Layer(start: 0.01, duration: 0.26, pitch: 783.99, partials: [1, 0.35, 0.12], attack: 0.004, decay: 5, volume: 0.22),
            ]),
            // Two falling notes: out.
            .back: Self.render(format: format, duration: 0.2, layers: [
                Layer(duration: 0.08, pitch: 659.25, partials: [1, 0.2], attack: 0.003, decay: 6, volume: 0.15),
                Layer(start: 0.08, duration: 0.11, pitch: 440, partials: [1, 0.2], attack: 0.003, decay: 6, volume: 0.15),
            ]),
            // A low, soft settle.
            .pause: Self.render(format: format, duration: 0.4, layers: [
                Layer(duration: 0.38, pitch: 261.63, pitchEnd: 220, partials: [1, 0.15], attack: 0.03, decay: 3, volume: 0.14),
            ]),
            // A short upward swell, just before the voice.
            .speak: Self.render(format: format, duration: 0.18, layers: [
                Layer(duration: 0.16, pitch: 392, pitchEnd: 587.33, partials: [1, 0.2], attack: 0.04, decay: 3, volume: 0.13),
            ]),
            // A muffled low knock.
            .unavailable: Self.render(format: format, duration: 0.2, layers: [
                Layer(duration: 0.18, pitch: 130.81, partials: [1, 0.3], noise: 0.3, brightness: 0.15, attack: 0.004, decay: 5, volume: 0.22),
            ]),
        ]
        buffers = rendered.compactMapValues { $0 }
        observeInterruptions()
    }

    func prepare() {
        guard let format else { return }
        if !isWired {
            for node in nodes {
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: format)
            }
            isWired = true
        }
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        for node in nodes where !node.isPlaying {
            node.play()
        }
    }

    func play(_ event: FeedbackEvent) {
        guard let buffer = buffers[event] else { return }
        prepare()
        guard engine.isRunning, !nodes.isEmpty else { return }
        let node = nodes[nextNode]
        nextNode = (nextNode + 1) % nodes.count
        node.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
    }

    private func observeInterruptions() {
        let center = NotificationCenter.default
        center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            Task { @MainActor in self?.prepare() }
        }
        center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.recoverFromReset() }
        }
    }

    /// After a media-services reset the whole audio stack is invalid; the
    /// rendered buffers are plain memory and survive.
    private func recoverFromReset() {
        AudioSession.activate()
        engine = AVAudioEngine()
        nodes = (0..<3).map { _ in AVAudioPlayerNode() }
        nextNode = 0
        isWired = false
        prepare()
    }

    // MARK: - Synthesis

    private struct Layer {
        var start: Float = 0
        var duration: Float
        /// 0 means pure noise.
        var pitch: Float = 0
        /// Non-zero glides from `pitch` to here across the layer.
        var pitchEnd: Float = 0
        var partials: [Float] = [1]
        var noise: Float = 0
        /// One-pole low-pass coefficient for the noise: dull…sharp.
        var brightness: Float = 0.5
        var attack: Float = 0.004
        var decay: Float = 6
        var volume: Float = 0.3
    }

    private static func render(format: AVAudioFormat, duration: Double, layers: [Layer]) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?.pointee
        else { return nil }
        buffer.frameLength = frameCount
        let total = Int(frameCount)
        let sampleRate = Float(format.sampleRate)
        for index in 0..<total { channel[index] = 0 }

        for (layerIndex, layer) in layers.enumerated() {
            let startFrame = Int(layer.start * sampleRate)
            let layerFrames = max(Int(layer.duration * sampleRate), 1)
            // A fixed seed per layer: every launch renders identical sounds.
            var noiseState: UInt32 = 0x2F6E_2B1D &+ UInt32(layerIndex) &* 0x9E37_79B9
            var filtered: Float = 0
            var phase: Float = 0
            for offset in 0..<layerFrames {
                let frame = startFrame + offset
                guard frame >= 0, frame < total else { continue }
                let progress = Float(offset) / Float(layerFrames)
                let seconds = Float(offset) / sampleRate
                let attack = min(seconds / max(layer.attack, 0.0001), 1)
                let envelope = attack * expf(-layer.decay * progress)

                var sample: Float = 0
                if layer.pitch > 0 {
                    let frequency = layer.pitchEnd > 0
                        ? layer.pitch + (layer.pitchEnd - layer.pitch) * progress
                        : layer.pitch
                    phase += 2 * .pi * frequency / sampleRate
                    var tone: Float = 0
                    for (index, weight) in layer.partials.enumerated() {
                        tone += weight * sinf(phase * Float(index + 1))
                    }
                    sample += tone * (1 - layer.noise)
                }
                if layer.noise > 0 {
                    // xorshift32: cheap, deterministic white noise.
                    noiseState ^= noiseState << 13
                    noiseState ^= noiseState >> 17
                    noiseState ^= noiseState << 5
                    let white = Float(noiseState) / Float(UInt32.max) * 2 - 1
                    filtered += layer.brightness * (white - filtered)
                    sample += filtered * layer.noise
                }
                channel[frame] += sample * envelope * layer.volume
            }
        }

        var peak: Float = 0
        for index in 0..<total { peak = max(peak, abs(channel[index])) }
        if peak > 0.95 {
            let scale = 0.95 / peak
            for index in 0..<total { channel[index] *= scale }
        }
        return buffer
    }
}
