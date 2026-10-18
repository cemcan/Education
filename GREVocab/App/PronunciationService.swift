import AVFoundation

/// Speaks words and example sentences with on-device voices (works offline).
///
/// Sounds most natural with an Enhanced or Premium voice, which the user downloads once in
/// Settings › Accessibility › Spoken Content › Voices › English. The best installed voice is
/// picked automatically unless one is chosen in the app's Settings.
final class PronunciationService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = PronunciationService()

    /// The text currently being spoken, so buttons can show a "playing" state.
    @Published private(set) var speakingText: String?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: Voices

    /// English voices for the chosen accent, best quality first. Novelty voices
    /// (Bells, Bubbles, Whisper, …) are left out.
    static func availableVoices(for accent: VoiceAccent = AppSettings.accent) -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == accent.rawValue && !$0.voiceTraits.contains(.isNoveltyVoice) }
            .sorted {
                if $0.quality != $1.quality { return $0.quality.rank > $1.quality.rank }
                return $0.name < $1.name
            }
    }

    /// The saved voice if it's still installed, otherwise the best available one.
    static var currentVoice: AVSpeechSynthesisVoice? {
        if let id = AppSettings.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: id),
           voice.language == AppSettings.accent.rawValue {
            return voice
        }
        return availableVoices().first ?? AVSpeechSynthesisVoice(language: AppSettings.accent.rawValue)
    }

    /// True when only the basic compact voices are installed.
    static var hasOnlyBasicVoices: Bool {
        !availableVoices().contains { $0.quality != .default }
    }

    // MARK: Speaking

    /// Speaks a headword. With `ipa`, the speech engine follows the dictionary pronunciation
    /// instead of guessing from the spelling.
    func speak(word: String, ipa: String?) {
        let ipaText = ipa?.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        let utterance: AVSpeechUtterance
        if AppSettings.useIPA, let ipaText, !ipaText.isEmpty {
            let attributed = NSMutableAttributedString(string: word)
            attributed.addAttribute(NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute),
                                    value: ipaText,
                                    range: NSRange(location: 0, length: attributed.length))
            utterance = AVSpeechUtterance(attributedString: attributed)
        } else {
            utterance = AVSpeechUtterance(string: word)
        }
        // A touch slower than conversational speed so each syllable is clear.
        speak(utterance, text: word, rateScale: 0.85)
    }

    /// Speaks a sentence at a natural pace.
    func speak(_ text: String) {
        speak(AVSpeechUtterance(string: text), text: text, rateScale: 1.0)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speak(_ utterance: AVSpeechUtterance, text: String, rateScale: Float) {
        // .playback lets speech be heard even when the ring/silent switch is on silent.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        utterance.voice = Self.currentVoice
        let rate = AVSpeechUtteranceDefaultSpeechRate * Float(AppSettings.speechRate) * rateScale
        utterance.rate = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.prefersAssistiveTechnologySettings = false

        speakingText = text
        synthesizer.speak(utterance)
    }

    // MARK: AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finished()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finished()
    }

    private func finished() {
        DispatchQueue.main.async {
            guard !self.synthesizer.isSpeaking else { return }
            self.speakingText = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}

extension AVSpeechSynthesisVoiceQuality {
    fileprivate var rank: Int {
        switch self {
        case .premium: return 3
        case .enhanced: return 2
        default: return 1
        }
    }

    var label: String {
        switch self {
        case .premium: return "Premium"
        case .enhanced: return "Enhanced"
        default: return "Basic"
        }
    }
}
