import AVFoundation
import Accelerate
import MediaToolbox
import Synchronization

/// A gentle lift of the low bass, which makes songs sound a little deeper.
///
/// Each player item gets an audio tap that runs a low shelf filter over the
/// decoded audio. Switching it on or off fades between the plain and the
/// boosted sound over a moment, while the song plays. Streams of tracks the
/// server is still downloading are HLS, which taps don't see, so they play
/// as they are.
final class BassBoost: Sendable {
    static let shared = BassBoost()

    /// Whether the boost is on, read by the taps on the audio thread.
    let isOn = Atomic<Bool>(false)

    /// How much the low shelf lifts, around which frequency, and how much
    /// everything is turned down so the lifted bass doesn't clip.
    static let gainDB = 7.0
    static let frequency = 150.0
    static let headroomDB = -2.0
    /// Seconds the boost takes to fade in or out.
    static let fade = 0.15

    /// Taps [item]'s audio once its track is known.
    @MainActor static func attach(to item: AVPlayerItem) {
        Task {
            guard let track = try? await item.asset.loadTracks(withMediaType: .audio).first else { return }
            let state = Unmanaged.passRetained(TapState()).toOpaque()
            var callbacks = MTAudioProcessingTapCallbacks(
                version: kMTAudioProcessingTapCallbacksVersion_0, clientInfo: state,
                init: tapInit, finalize: tapFinalize, prepare: tapPrepare, unprepare: tapUnprepare,
                process: tapProcess)
            var tap: MTAudioProcessingTap?
            guard MTAudioProcessingTapCreate(
                kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap) == noErr,
                let tap
            else {
                Unmanaged<TapState>.fromOpaque(state).release()
                return
            }
            let parameters = AVMutableAudioMixInputParameters(track: track)
            parameters.audioTapProcessor = tap
            let mix = AVMutableAudioMix()
            mix.inputParameters = [parameters]
            item.audioMix = mix
        }
    }

    /// The low shelf's coefficients at [sampleRate], with the headroom, for
    /// vDSP's biquad: b0, b1, b2, a1, a2 over a0 (Audio EQ Cookbook).
    static func coefficients(sampleRate: Double) -> [Double] {
        let a = pow(10, gainDB / 40)
        let w0 = 2 * Double.pi * frequency / sampleRate
        let cosine = cos(w0)
        // A shelf slope of 1
        let alpha = sin(w0) / 2 * sqrt(2)
        let root = 2 * sqrt(a) * alpha
        let headroom = pow(10, headroomDB / 20)
        let b0 = a * ((a + 1) - (a - 1) * cosine + root)
        let b1 = 2 * a * ((a - 1) - (a + 1) * cosine)
        let b2 = a * ((a + 1) - (a - 1) * cosine - root)
        let a0 = (a + 1) + (a - 1) * cosine + root
        let a1 = -2 * ((a - 1) + (a + 1) * cosine)
        let a2 = (a + 1) + (a - 1) * cosine - root
        return [b0 * headroom / a0, b1 * headroom / a0, b2 * headroom / a0, a1 / a0, a2 / a0]
    }
}

/// What one tap keeps between buffers, touched only by its callbacks.
private final class TapState {
    var setup: vDSP_biquad_Setup?
    /// The filter's memory, per channel.
    var delays: [[Float]] = []
    var boosted: UnsafeMutablePointer<Float>?
    var ramp: UnsafeMutablePointer<Float>?
    var capacity = 0
    var sampleRate = 44_100.0
    var canProcess = false
    /// How far the boost is faded in, from 0 to 1.
    var amount: Float = 0
}

private func state(_ tap: MTAudioProcessingTap) -> TapState {
    Unmanaged<TapState>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
}

private let tapInit: MTAudioProcessingTapInitCallback = { _, clientInfo, storage in
    storage.pointee = clientInfo
}

private let tapFinalize: MTAudioProcessingTapFinalizeCallback = { tap in
    Unmanaged<TapState>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release()
}

private let tapPrepare: MTAudioProcessingTapPrepareCallback = { tap, maxFrames, format in
    let state = state(tap)
    let description = format.pointee
    let flags = description.mFormatFlags
    // Decoded audio comes as floats, a buffer per channel
    state.canProcess =
        description.mFormatID == kAudioFormatLinearPCM && flags & kAudioFormatFlagIsFloat != 0
        && flags & kAudioFormatFlagIsNonInterleaved != 0 && description.mBitsPerChannel == 32
    guard state.canProcess else { return }
    state.sampleRate = description.mSampleRate
    state.setup = vDSP_biquad_CreateSetup(BassBoost.coefficients(sampleRate: description.mSampleRate), 1)
    state.delays = Array(repeating: [Float](repeating: 0, count: 4), count: Int(description.mChannelsPerFrame))
    state.capacity = Int(maxFrames)
    state.boosted = .allocate(capacity: state.capacity)
    state.ramp = .allocate(capacity: state.capacity)
}

private let tapUnprepare: MTAudioProcessingTapUnprepareCallback = { tap in
    let state = state(tap)
    if let setup = state.setup { vDSP_biquad_DestroySetup(setup) }
    state.setup = nil
    state.boosted?.deallocate()
    state.ramp?.deallocate()
    state.boosted = nil
    state.ramp = nil
    state.canProcess = false
}

private let tapProcess: MTAudioProcessingTapProcessCallback = {
    tap, frames, _, buffers, framesOut, flagsOut in
    guard MTAudioProcessingTapGetSourceAudio(tap, frames, buffers, flagsOut, nil, framesOut) == noErr else { return }
    let state = state(tap)
    let count = Int(framesOut.pointee)
    guard state.canProcess, let setup = state.setup, let boosted = state.boosted, let ramp = state.ramp,
        count > 0, count <= state.capacity
    else { return }
    let target: Float = BassBoost.shared.isOn.load(ordering: .relaxed) ? 1 : 0
    let start = state.amount
    if start == 0 && target == 0 {
        // Off: the audio plays as it is, and the filter starts afresh when turned on
        for channel in state.delays.indices { state.delays[channel] = [0, 0, 0, 0] }
        return
    }
    let step = Float(Double(count) / (BassBoost.fade * state.sampleRate))
    let end = target > start ? min(start + step, 1) : max(start - step, 0)
    state.amount = end
    var first = start
    var increment = (end - start) / Float(count)
    vDSP_vramp(&first, &increment, ramp, 1, vDSP_Length(count))
    for (channel, buffer) in UnsafeMutableAudioBufferListPointer(buffers).enumerated() {
        guard channel < state.delays.count, let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
            continue
        }
        vDSP_biquad(setup, &state.delays[channel], data, 1, boosted, 1, vDSP_Length(count))
        // The plain audio, plus as much of the difference the boost makes as is faded in
        vDSP_vsub(data, 1, boosted, 1, boosted, 1, vDSP_Length(count))
        vDSP_vma(boosted, 1, ramp, 1, data, 1, data, 1, vDSP_Length(count))
    }
}
