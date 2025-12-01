import Foundation
import AVFoundation
import Speech

class VoiceAssistant: ObservableObject {
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var currentMessage = ""
    @Published var conversationHistory: [ConversationMessage] = []
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let openVoiceService = OpenVoiceService()
    
    struct ConversationMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date
        let emoji: String?
    }
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        requestSpeechAuthorization()
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("✅ Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("⚠️ Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("❌ Speech recognizer not available")
            return
        }
        
        stopListening()
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.currentMessage = text
                }
                
                if result.isFinal {
                    self.processUserMessage(text)
                }
            }
            
            if let error = error {
                print("❌ Recognition error: \(error)")
                self.stopListening()
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
            print("✅ Started listening")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
            self.currentMessage = ""
        }
    }
    
    func handleTap() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    private func processUserMessage(_ text: String) {
        let userMessage = ConversationMessage(
            text: text,
            isUser: true,
            timestamp: Date(),
            emoji: nil
        )
        
        DispatchQueue.main.async {
            self.conversationHistory.append(userMessage)
        }
        
        // Process with wellbeing coach
        Task {
            await processWithWellbeingCoach(text)
        }
    }
    
    private func processWithWellbeingCoach(_ text: String) async {
        // This will be called by WellbeingCoach
        NotificationCenter.default.post(
            name: NSNotification.Name("UserMessageReceived"),
            object: text
        )
    }
    
    func speak(_ text: String, emoji: String? = nil) async {
        await MainActor.run {
            self.isSpeaking = true
        }
        
        // Use OpenVoice service to generate speech
        if let audioData = await openVoiceService.synthesize(text: text) {
            await playAudio(audioData)
        } else {
            // Fallback to system TTS
            await speakWithSystemTTS(text)
        }
        
        let assistantMessage = ConversationMessage(
            text: text,
            isUser: false,
            timestamp: Date(),
            emoji: emoji
        )
        
        await MainActor.run {
            self.conversationHistory.append(assistantMessage)
            self.isSpeaking = false
        }
    }
    
    private func speakWithSystemTTS(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        let synthesizer = AVSpeechSynthesizer()
        
        await withCheckedContinuation { continuation in
            let delegate = SpeechDelegate {
                continuation.resume()
            }
            synthesizer.delegate = delegate
            synthesizer.speak(utterance)
        }
    }
    
    private func playAudio(_ data: Data) async {
        // Play audio data using AVAudioPlayer
        // Implementation depends on OpenVoice service response format
    }
}

class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion()
    }
}

