import AVFoundation
import Foundation
import Observation
import Speech

enum AudioSessionManager {
    static func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Text to speech

/// Speaks French with the best installed voice. Download "Enhanced" or
/// "Premium" French voices in iOS Settings > Accessibility > Spoken Content
/// for much more natural audio.
@Observable
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()

    private(set) var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    static let voiceKey = "voiceIdentifier"
    static let rateKey = "speechRate"

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    static var frenchVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("fr") }
            .sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    static var selectedVoice: AVSpeechSynthesisVoice? {
        if let id = UserDefaults.standard.string(forKey: voiceKey),
           let voice = AVSpeechSynthesisVoice(identifier: id) {
            return voice
        }
        let france = frenchVoices.filter { $0.language == "fr-FR" }
        return france.first ?? frenchVoices.first ?? AVSpeechSynthesisVoice(language: "fr-FR")
    }

    func speak(_ text: String, slow: Bool = false) {
        try? AudioSessionManager.activate()
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.selectedVoice
        let stored = UserDefaults.standard.object(forKey: Self.rateKey) as? Double ?? 1.0
        let base = AVSpeechUtteranceDefaultSpeechRate * Float(stored)
        utterance.rate = slow ? base * 0.6 : base
        utterance.preUtteranceDelay = 0.05
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}

// MARK: - Speech recognition

/// Records the microphone and transcribes French speech, on-device when the
/// French model is available.
@Observable
final class SpeechRecognizer {
    private(set) var transcript = ""
    private(set) var isRecording = false
    private(set) var audioLevel: Float = 0
    var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var onFinish: ((String) -> Void)?
    @ObservationIgnored private var silenceTimer: Timer?
    @ObservationIgnored private var maxTimer: Timer?
    /// Incremented per recording so late callbacks from an old one are ignored.
    @ObservationIgnored private var generation = 0

    /// Seconds of silence after speech before recording stops on its own.
    var silenceTimeout: TimeInterval = 1.6

    static func requestPermissions() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechAuthorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    /// Starts listening. `onFinish` is called once with the final transcript
    /// (possibly empty) when recording ends.
    @MainActor
    func start(onFinish: @escaping (String) -> Void) async {
        guard !isRecording else { return }
        errorMessage = nil
        transcript = ""

        guard await Self.requestPermissions() else {
            errorMessage = "Allow microphone and speech recognition access in Settings to practise speaking."
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "French speech recognition isn't available right now. Check your connection, or add French under Settings > General > Keyboard > Dictation."
            return
        }

        Speaker.shared.stop()
        generation += 1
        let current = generation
        self.onFinish = onFinish

        do {
            try AudioSessionManager.activate()

            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = .dictation
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                request.append(buffer)
                let level = Self.level(of: buffer)
                DispatchQueue.main.async { self?.audioLevel = level }
            }

            engine.prepare()
            try engine.start()

            self.engine = engine
            self.request = request
            isRecording = true

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self, self.generation == current else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        self.resetSilenceTimer()
                        if result.isFinal { self.finish() }
                    }
                    if error != nil { self.finish() }
                }
            }

            maxTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
                self?.stop()
            }
        } catch {
            errorMessage = error.localizedDescription
            teardownAudio()
            self.onFinish = nil
        }
    }

    /// Stops recording; the final result is delivered via `onFinish`.
    func stop() {
        guard isRecording else { return }
        request?.endAudio()
        teardownAudio()
        // Safety net in case the recognizer never reports a final result.
        let current = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, self.generation == current else { return }
            self.finish()
        }
    }

    /// Stops without delivering a result.
    func cancel() {
        generation += 1
        onFinish = nil
        task?.cancel()
        task = nil
        teardownAudio()
    }

    private func finish() {
        teardownAudio()
        task?.cancel()
        task = nil
        request = nil
        guard let callback = onFinish else { return }
        onFinish = nil
        callback(transcript)
    }

    private func teardownAudio() {
        silenceTimer?.invalidate()
        maxTimer?.invalidate()
        silenceTimer = nil
        maxTimer = nil
        if let engine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        engine = nil
        isRecording = false
        audioLevel = 0
    }

    private func resetSilenceTimer() {
        guard isRecording else { return }
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            self?.stop()
        }
    }

    private static func level(of buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        return min(1, sqrt(sum / Float(count)) * 10)
    }
}
