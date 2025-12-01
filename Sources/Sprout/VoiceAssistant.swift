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
    
    // Conversation awareness
    private var pauseTimer: Timer?
    private var accumulatedText = ""
    private let pauseThreshold: TimeInterval = 2.0 // 2 seconds of silence = pause
    private var lastSpeechTime: Date?
    
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
                    // Update accumulated text with latest transcription
                    self.accumulatedText = text
                    self.lastSpeechTime = Date()
                    
                    // Reset pause timer - user is still speaking
                    self.resetPauseTimer()
                }
                
                if result.isFinal {
                    // Final result - process after a pause
                    DispatchQueue.main.async {
                        self.accumulatedText = text
                        self.lastSpeechTime = Date()
                        self.startPauseTimer()
                    }
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                // Only log non-cancellation errors
                if nsError.code != 301 && nsError.code != 216 { // 301 = canceled, 216 = no speech (normal)
                    print("❌ Recognition error: \(error.localizedDescription)")
                }
                // Don't stop listening for "no speech" errors - user might still be speaking
                if nsError.code == 301 { // Canceled
                    self.stopListening()
                } else if nsError.code != 216 { // No speech detected is normal, don't stop
                    self.stopListening()
                }
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
        pauseTimer?.invalidate()
        pauseTimer = nil
        
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
            // Process any accumulated text before stopping
            if !self.accumulatedText.isEmpty {
                self.processUserMessage(self.accumulatedText)
                self.accumulatedText = ""
            }
        }
    }
    
    private func resetPauseTimer() {
        pauseTimer?.invalidate()
        pauseTimer = nil
    }
    
    private func startPauseTimer() {
        resetPauseTimer()
        
        pauseTimer = Timer.scheduledTimer(withTimeInterval: pauseThreshold, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Pause detected - process accumulated text
            if !self.accumulatedText.isEmpty {
                self.processUserMessage(self.accumulatedText)
                self.accumulatedText = ""
            }
        }
    }
    
    func handleTap() {
        if isListening {
            // Small delay to allow any final recognition to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.stopListening()
            }
        } else {
            // Small delay before starting to avoid immediate cancellation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.startListening()
            }
        }
    }
    
    private func processUserMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let userMessage = ConversationMessage(
            text: trimmedText,
            isUser: true,
            timestamp: Date(),
            emoji: nil
        )
        
        DispatchQueue.main.async {
            self.conversationHistory.append(userMessage)
        }
        
        // Process with wellbeing coach (with conversation context)
        Task {
            await processWithWellbeingCoach(trimmedText)
        }
    }
    
    private func processWithWellbeingCoach(_ text: String) async {
        // Pass conversation context to WellbeingCoach
        let context = getConversationContext()
        NotificationCenter.default.post(
            name: NSNotification.Name("UserMessageReceived"),
            object: ["text": text, "context": context]
        )
    }
    
    private func getConversationContext() -> String {
        // Get last 5 messages for context (excluding current one)
        let recentMessages = conversationHistory.suffix(5)
        return recentMessages.map { msg in
            let role = msg.isUser ? "User" : "Sprout"
            return "\(role): \(msg.text)"
        }.joined(separator: "\n")
    }
    
    func speak(_ text: String, emoji: String? = nil) async {
        await MainActor.run {
            self.isSpeaking = true
        }
        
        // Use OpenVoice service to generate speech
        if let audioData = await openVoiceService.synthesize(text: text) {
            await playAudio(audioData)
        } else {
            // Fallback to system TTS (silently - OpenVoice errors are expected if models not loaded)
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
        var delegate: SpeechDelegate?
        
        await withCheckedContinuation { continuation in
            var hasResumed = false
            let resumeOnce = {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume()
                }
            }
            
            delegate = SpeechDelegate {
                resumeOnce()
            }
            synthesizer.delegate = delegate
            
            // Start speaking
            synthesizer.speak(utterance)
            
            // Timeout safety - ensure continuation always resumes
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds max
                resumeOnce()
            }
        }
        
        // Clean up
        synthesizer.delegate = nil
        delegate = nil
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

