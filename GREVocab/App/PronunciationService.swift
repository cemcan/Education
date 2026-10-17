import AVFoundation

/// Speaks words and example sentences with the on-device voices (works offline).
final class PronunciationService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = PronunciationService()

    /// The text currently being spoken, so buttons can show a "playing" state.
    @Published private(set) var speakingText: String?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        // .playback lets speech be heard even when the ring/silent switch is on silent.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AppSettings.accent.rawValue)
        let rate = AVSpeechUtteranceDefaultSpeechRate * Float(AppSettings.speechRate)
        utterance.rate = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        speakingText = text
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finished(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finished(utterance)
    }

    private func finished(_ utterance: AVSpeechUtterance) {
        let text = utterance.speechString
        DispatchQueue.main.async {
            if self.speakingText == text { self.speakingText = nil }
            if !self.synthesizer.isSpeaking {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        }
    }
}
