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
    private var silenceTimer: Timer?
    private var noSpeechTimer: Timer?
    private var accumulatedText = ""
    private let pauseThreshold: TimeInterval = 2.0 // 2 seconds of silence = pause and process
    private let silenceStopThreshold: TimeInterval = 8.0 // 8 seconds of silence = stop listening
    private let noSpeechStopThreshold: TimeInterval = 5.0 // 5 seconds of no speech detected = stop listening
    private var lastSpeechTime: Date?
    private var noSpeechErrorCount = 0
    
    // TTS control
    private var currentSynthesizer: AVSpeechSynthesizer?
    
    struct ConversationMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date
        let emoji: String?
        var analysis: String? = nil
    }
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        requestSpeechAuthorization()
        setupAnalysisListener()
    }
    
    private func setupAnalysisListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ConversationAnalysis"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let dict = notification.object as? [String: String],
               let analysis = dict["analysis"],
               !analysis.isEmpty,
               let lastMessage = self.conversationHistory.last,
               !lastMessage.isUser {
                // Update the last assistant message with analysis
                if let index = self.conversationHistory.firstIndex(where: { $0.id == lastMessage.id }) {
                    var updatedMessage = lastMessage
                    updatedMessage.analysis = analysis
                    self.conversationHistory[index] = updatedMessage
                }
            }
        }
    }
    
    func deleteConversation(at index: Int) {
        guard index >= 0 && index < conversationHistory.count else { return }
        conversationHistory.remove(at: index)
    }
    
    func deleteAllConversations() {
        conversationHistory.removeAll()
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
        
        // Don't restart if already listening
        if isListening {
            return
        }
        
        stopListening()
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            print("❌ Failed to create audio engine")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Failed to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    // Always update current message for real-time display
                    self.currentMessage = text
                    // Update accumulated text with latest transcription
                    self.accumulatedText = text
                    self.lastSpeechTime = Date()
                    
                    // Reset pause timer - user is still speaking
                    self.resetPauseTimer()
                    // Reset silence timer - user is speaking
                    self.resetSilenceTimer()
                    // Reset no speech timer - speech detected
                    self.resetNoSpeechTimer()
                    self.noSpeechErrorCount = 0
                }
                
                if result.isFinal {
                    // Final result - process after a pause
                    DispatchQueue.main.async {
                        self.accumulatedText = text
                        self.lastSpeechTime = Date()
                        self.startPauseTimer()
                        self.startSilenceTimer() // Also start silence timer for auto-stop
                    }
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                // Only log non-cancellation errors
                if nsError.code != 301 && nsError.code != 216 { // 301 = canceled, 216 = no speech (normal)
                    print("❌ Recognition error: \(error.localizedDescription)")
                }
                
                if nsError.code == 301 { // Canceled
                    self.stopListening()
                } else if nsError.code == 216 { // No speech detected
                    // Track no speech errors
                    DispatchQueue.main.async {
                        self.noSpeechErrorCount += 1
                        // Start timer to stop if no speech continues
                        self.startNoSpeechTimer()
                    }
                } else {
                    // For other errors, try to restart listening
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !self.isListening {
                            self.startListening()
                        }
                    }
                }
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                // Start silence timer when listening begins
                self.startSilenceTimer()
            }
            print("✅ Started listening")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            // Try again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !self.isListening {
                    self.startListening()
                }
            }
        }
    }
    
    func stopListening() {
        pauseTimer?.invalidate()
        pauseTimer = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        noSpeechTimer?.invalidate()
        noSpeechTimer = nil
        noSpeechErrorCount = 0
        
        // Process any accumulated text before stopping
        let textToProcess = accumulatedText
        accumulatedText = ""
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
            // Keep current message visible for a moment, then clear
            if !textToProcess.isEmpty {
                self.processUserMessage(textToProcess)
                // Clear after processing
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.currentMessage == textToProcess {
                        self.currentMessage = ""
                    }
                }
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
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    private func startSilenceTimer() {
        resetSilenceTimer()
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceStopThreshold, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Long silence detected - stop listening automatically
            if self.isListening {
                self.stopListening()
                
                // Auto-restart listening after a brief pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.startListening()
                }
            }
        }
    }
    
    private func resetNoSpeechTimer() {
        noSpeechTimer?.invalidate()
        noSpeechTimer = nil
    }
    
    private func startNoSpeechTimer() {
        resetNoSpeechTimer()
        
        noSpeechTimer = Timer.scheduledTimer(withTimeInterval: noSpeechStopThreshold, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // No speech detected for threshold period - stop listening
            if self.isListening && self.noSpeechErrorCount > 0 {
                self.stopListening()
                
                // Auto-restart listening after a brief pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.startListening()
                }
            }
        }
    }
    
    func handleTap() {
        // If speaking, stop speaking first
        if isSpeaking {
            stopSpeaking()
            return
        }
        
        // Otherwise, toggle listening on tap
        if isListening {
            // Stop listening immediately when tapped
            stopListening()
        } else {
            // Start listening when tapped (if not already listening)
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
            let role = msg.isUser ? "Seedling!" : "Sprout"
            return "\(role): \(msg.text)"
        }.joined(separator: "\n")
    }
    
    func speak(_ text: String, emoji: String? = nil, analysis: String? = nil) async {
        await MainActor.run {
            self.isSpeaking = true
        }
        
        // Filter emojis from text before speaking (keep original for display)
        let textForSpeech = removeEmojis(from: text)
        
        // Check if OpenVoice service is available first
        let serviceAvailable = await openVoiceService.checkServiceAvailable()
        
        if serviceAvailable {
            // Use OpenVoice service to generate speech with Jon's voice
            print("🎤 Attempting OpenVoice synthesis...")
            if let audioData = await openVoiceService.synthesize(text: textForSpeech) {
                print("✅ Using OpenVoice (Jon's voice) for speech")
                await playAudio(audioData)
            } else {
                print("⚠️ OpenVoice synthesis failed, falling back to system TTS")
                await speakWithSystemTTS(textForSpeech)
            }
        } else {
            print("⚠️ OpenVoice service not available on port 6000, using system TTS")
            print("   Make sure to start the service: ./services/start_openvoice.sh")
            await speakWithSystemTTS(textForSpeech)
        }
        
        let assistantMessage = ConversationMessage(
            text: text,
            isUser: false,
            timestamp: Date(),
            emoji: emoji,
            analysis: analysis
        )
        
        await MainActor.run {
            self.conversationHistory.append(assistantMessage)
            self.isSpeaking = false
        }
    }
    
    // Helper function to remove emojis from text
    private func removeEmojis(from text: String) -> String {
        return text.unicodeScalars
            .filter { scalar in
                // Filter out emoji ranges
                !(0x1F600...0x1F64F).contains(scalar.value) && // Emoticons
                !(0x1F300...0x1F5FF).contains(scalar.value) && // Misc Symbols and Pictographs
                !(0x1F680...0x1F6FF).contains(scalar.value) && // Transport and Map
                !(0x1F1E0...0x1F1FF).contains(scalar.value) && // Flags
                !(0x2600...0x26FF).contains(scalar.value) &&   // Misc symbols
                !(0x2700...0x27BF).contains(scalar.value) &&   // Dingbats
                !(0xFE00...0xFE0F).contains(scalar.value) &&   // Variation Selectors
                !(0x1F900...0x1F9FF).contains(scalar.value) &&  // Supplemental Symbols and Pictographs
                !(0x1FA00...0x1FAFF).contains(scalar.value)     // Chess Symbols, Symbols and Pictographs Extended-A
            }
            .reduce("") { $0 + String($1) }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func speakWithSystemTTS(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        let synthesizer = AVSpeechSynthesizer()
        currentSynthesizer = synthesizer
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
        currentSynthesizer = nil
    }
    
    func stopSpeaking() {
        Task { @MainActor in
            if isSpeaking {
                currentSynthesizer?.stopSpeaking(at: .immediate)
                currentSynthesizer = nil
                isSpeaking = false
                print("🛑 Speech stopped by user")
            }
        }
    }
    
    private func playAudio(_ data: Data) async {
        // Play audio data from OpenVoice using AVAudioPlayer
        return await withCheckedContinuation { continuation in
            do {
                let audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer.prepareToPlay()
                
                // Use delegate to know when playback finishes
                class AudioDelegate: NSObject, AVAudioPlayerDelegate {
                    let continuation: CheckedContinuation<Void, Never>
                    
                    init(continuation: CheckedContinuation<Void, Never>) {
                        self.continuation = continuation
                    }
                    
                    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
                        continuation.resume()
                    }
                    
                    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
                        print("❌ OpenVoice: Audio decode error - \(error?.localizedDescription ?? "unknown")")
                        continuation.resume()
                    }
                }
                
                let delegate = AudioDelegate(continuation: continuation)
                audioPlayer.delegate = delegate
                
                // Store delegate reference to prevent deallocation
                // Use a local variable to keep reference alive
                let _ = delegate
                
                // Play audio
                if audioPlayer.play() {
                    print("✅ OpenVoice: Playing audio (\(data.count) bytes)")
                } else {
                    print("❌ OpenVoice: Failed to start playback")
                    continuation.resume()
                }
                
                // Timeout safety
                Task {
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds max
                    if audioPlayer.isPlaying {
                        audioPlayer.stop()
                        continuation.resume()
                    }
                }
            } catch {
                print("❌ OpenVoice: Failed to create audio player - \(error.localizedDescription)")
                continuation.resume()
            }
        }
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

