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
    private let pauseThreshold: TimeInterval = 1.0 // 1 second of silence after speech = process message (faster response)
    private let silenceStopThreshold: TimeInterval = 8.0 // 8 seconds of total silence = stop listening
    private let noSpeechStopThreshold: TimeInterval = 5.0 // 5 seconds of no speech detected = stop listening
    private var lastSpeechTime: Date?
    private var noSpeechErrorCount = 0
    
    // TTS control
    private var currentSynthesizer: AVSpeechSynthesizer?
    var currentAudioPlayer: AVAudioPlayer? // For OpenVoice playback (internal for AudioDelegate access)
    var audioPlayerDelegate: AudioDelegate? // Keep reference to prevent deallocation (internal for AudioDelegate access)
    var audioContinuation: CheckedContinuation<Void, Never>? // Store continuation for early stop (internal for AudioDelegate access)
    
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
                    
                    // Reset pause timer - user is still speaking (will trigger when they stop)
                    self.resetPauseTimer()
                    // Reset silence timer - user is speaking
                    self.resetSilenceTimer()
                    // Reset no speech timer - speech detected
                    self.resetNoSpeechTimer()
                    self.noSpeechErrorCount = 0
                }
                
                if result.isFinal {
                    // Final result - transcription is finished, process immediately and send to AI
                    DispatchQueue.main.async {
                        self.accumulatedText = text
                        self.lastSpeechTime = Date()
                        
                        // Transcription finished - process immediately, no waiting!
                        print("✅ Transcription finished: \(text.prefix(50))...")
                        if !self.accumulatedText.isEmpty {
                            let textToProcess = self.accumulatedText
                            self.accumulatedText = ""
                            // Stop listening while processing (will restart after AI responds)
                            self.stopListening()
                            // Send to AI immediately
                            self.processUserMessage(textToProcess)
                        }
                    }
                } else {
                    // Partial result - user is still speaking
                    // Start/reset pause timer to detect when they stop
                    DispatchQueue.main.async {
                        // Reset and restart pause timer - will process when speech stops
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
            } else {
                // If no text to process, restart listening after a brief pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !self.isListening && !self.isSpeaking {
                        self.startListening()
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
        
        // Start timer to detect when user stops speaking
        // If no speech updates for pauseThreshold seconds, process the message
        pauseTimer = Timer.scheduledTimer(withTimeInterval: pauseThreshold, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // No speech detected for pauseThreshold - user has finished speaking
            // Process accumulated text and send to AI
            if !self.accumulatedText.isEmpty && self.isListening {
                let textToProcess = self.accumulatedText
                self.accumulatedText = ""
                print("🔇 Silence detected - processing message: \(textToProcess.prefix(50))...")
                // Stop listening while processing (will restart after AI responds)
                self.stopListening()
                self.processUserMessage(textToProcess)
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
        if isSpeaking {
            // If speaking, stop immediately and restart listening
            stopSpeaking()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !self.isListening {
                    self.startListening()
                }
            }
        } else if isListening {
            // If listening, stop immediately (user wants to interrupt)
            stopListening()
        } else {
            // If not speaking or listening, start listening
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.startListening()
            }
        }
    }
    
    private func processUserMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            // If empty, just restart listening
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.isListening && !self.isSpeaking {
                    self.startListening()
                }
            }
            return
        }
        
        print("📤 Sending to AI: \(trimmedText.prefix(50))...")
        
        let userMessage = ConversationMessage(
            text: trimmedText,
            isUser: true,
            timestamp: Date(),
            emoji: nil
        )
        
        DispatchQueue.main.async {
            self.conversationHistory.append(userMessage)
        }
        
        // Process with wellbeing coach immediately (with conversation context)
        Task {
            await processWithWellbeingCoach(trimmedText)
        }
    }
    
    private func processWithWellbeingCoach(_ text: String) async {
        // Pass conversation context to WellbeingCoach immediately
        let context = getConversationContext()
        print("🤖 Triggering AI prompt with context...")
        NotificationCenter.default.post(
            name: NSNotification.Name("UserMessageReceived"),
            object: ["text": text, "context": context]
        )
    }
    
    private func getConversationContext() -> String {
        // Get last 8 messages for better context (excluding current one)
        // This helps the AI see more conversation history and avoid repetition
        let recentMessages = conversationHistory.suffix(8)
        return recentMessages.map { msg in
            let role = msg.isUser ? "Seedling!" : "Sprout"
            return "\(role): \(msg.text)"
        }.joined(separator: "\n")
    }
    
    func speak(_ text: String, emoji: String? = nil, analysis: String? = nil, voiceStyle: SettingsManager.VoiceType? = nil) async {
        await MainActor.run {
            self.isSpeaking = true
        }
        
        // Filter emojis from text before speaking (keep original for display)
        let textForSpeech = removeEmojis(from: text)
        
        // Check if OpenVoice service is available first
        let serviceAvailable = await openVoiceService.checkServiceAvailable()
        
        if serviceAvailable {
        // Get voice type - use provided style, test style, or default from settings
        let settingsManager = SettingsManager.shared
        let effectiveVoiceType: SettingsManager.VoiceType
        if let providedStyle = voiceStyle {
            effectiveVoiceType = providedStyle
        } else if let testStyle = settingsManager.testVoiceStyle {
            effectiveVoiceType = testStyle
        } else {
            effectiveVoiceType = settingsManager.voiceType
        }
        let voiceTypeString = effectiveVoiceType.openVoiceSpeaker
            
            // Use OpenVoice service to generate speech with Jon's voice
            print("🎤 Attempting OpenVoice synthesis... (voice: \(effectiveVoiceType.displayName))")
            if let audioData = await openVoiceService.synthesize(text: textForSpeech, voiceType: voiceTypeString) {
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
            // isSpeaking will be set to false when audio finishes (in delegates)
            // Listening will restart automatically in the delegates
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
        utterance.rate = 0.55  // 10% faster (was 0.5)
        
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
            
            delegate = SpeechDelegate(voiceAssistant: self, completion: {
                resumeOnce()
            })
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
        
        // Set isSpeaking to false after TTS completes
        // (Listening restart is handled in SpeechDelegate.didFinish)
        await MainActor.run {
            self.isSpeaking = false
        }
    }
    
    func stopSpeaking() {
        Task { @MainActor in
            if isSpeaking {
                // Stop system TTS
                if let synthesizer = currentSynthesizer, synthesizer.isSpeaking {
                    synthesizer.stopSpeaking(at: .immediate)
                    currentSynthesizer = nil
                }
                
                // Stop OpenVoice audio playback
                if let player = currentAudioPlayer, player.isPlaying {
                    player.stop()
                    currentAudioPlayer = nil
                    
                    // Resume continuation if it exists (fixes leak)
                    if let continuation = audioContinuation {
                        continuation.resume()
                        audioContinuation = nil
                    }
                }
                
                // Clean up delegate
                audioPlayerDelegate = nil
                
                isSpeaking = false
                print("🛑 Speech stopped by user")
            }
        }
    }
    
    private func playAudio(_ data: Data) async {
        // Play audio data from OpenVoice using AVAudioPlayer
        return await withCheckedContinuation { continuation in
            // Store continuation so it can be resumed if stopped early
            self.audioContinuation = continuation
            
            do {
                let audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer.prepareToPlay()
                
                // Store player reference
                self.currentAudioPlayer = audioPlayer
                
                // Create delegate to handle playback completion
                let delegate = AudioDelegate(voiceAssistant: self)
                audioPlayer.delegate = delegate
                
                // Store delegate reference to prevent deallocation
                self.audioPlayerDelegate = delegate
                
                // Play audio
                if audioPlayer.play() {
                    print("✅ OpenVoice: Playing audio (\(data.count) bytes)")
                } else {
                    print("❌ OpenVoice: Failed to start playback")
                    continuation.resume()
                    self.audioContinuation = nil
                    self.currentAudioPlayer = nil
                    self.audioPlayerDelegate = nil
                }
                
                // Timeout safety
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds max
                    if let player = self?.currentAudioPlayer, player.isPlaying {
                        player.stop()
                        if let continuation = self?.audioContinuation {
                            continuation.resume()
                            self?.audioContinuation = nil
                        }
                        self?.currentAudioPlayer = nil
                        self?.audioPlayerDelegate = nil
                    }
                }
            } catch {
                print("❌ OpenVoice: Failed to create audio player - \(error.localizedDescription)")
                continuation.resume()
                self.audioContinuation = nil
            }
        }
    }
}

class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var voiceAssistant: VoiceAssistant?
    let completion: () -> Void
    
    init(voiceAssistant: VoiceAssistant? = nil, completion: @escaping () -> Void) {
        self.voiceAssistant = voiceAssistant
        self.completion = completion
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion()
        
        // Restart listening after speech finishes
        if let assistant = voiceAssistant {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !assistant.isListening && !assistant.isSpeaking {
                    print("🔄 Restarting listening after system TTS finished")
                    assistant.startListening()
                }
            }
        }
    }
}

// Delegate for AVAudioPlayer to handle completion
class AudioDelegate: NSObject, AVAudioPlayerDelegate {
    weak var voiceAssistant: VoiceAssistant?
    
    init(voiceAssistant: VoiceAssistant) {
        self.voiceAssistant = voiceAssistant
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Resume continuation and clean up
        if let continuation = voiceAssistant?.audioContinuation {
            continuation.resume()
            voiceAssistant?.audioContinuation = nil
        }
        voiceAssistant?.currentAudioPlayer = nil
        voiceAssistant?.audioPlayerDelegate = nil
        
        // Set isSpeaking to false
        voiceAssistant?.isSpeaking = false
        
        // Restart listening after audio finishes
        if let assistant = voiceAssistant {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !assistant.isListening && !assistant.isSpeaking {
                    print("🔄 Restarting listening after OpenVoice audio finished")
                    assistant.startListening()
                }
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ OpenVoice: Audio decode error - \(error?.localizedDescription ?? "unknown")")
        // Resume continuation and clean up
        if let continuation = voiceAssistant?.audioContinuation {
            continuation.resume()
            voiceAssistant?.audioContinuation = nil
        }
        voiceAssistant?.currentAudioPlayer = nil
        voiceAssistant?.audioPlayerDelegate = nil
        
        // Restart listening even on error
        if let assistant = voiceAssistant {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !assistant.isListening && !assistant.isSpeaking {
                    print("🔄 Restarting listening after audio error")
                    assistant.startListening()
                }
            }
        }
    }
}

