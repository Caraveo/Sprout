import Foundation

class WellbeingCoach: ObservableObject {
    @Published var currentMood: Mood = .neutral
    @Published var breathingExerciseActive = false
    @Published var sessionActive = false
    @Published var dailyStreak = 0
    @Published var weeklyProgress: [Date: Int] = [:]
    
    enum Mood: String, CaseIterable {
        case great = "Great"
        case good = "Good"
        case neutral = "Neutral"
        case low = "Low"
        case struggling = "Struggling"
        
        var emoji: String {
            switch self {
            case .great: return "🌟"
            case .good: return "😊"
            case .neutral: return "😐"
            case .low: return "😔"
            case .struggling: return "💙"
            }
        }
    }
    
    private let breathingExercises = [
        BreathingExercise(name: "4-7-8 Breathing", duration: 120, pattern: [4, 7, 8], emoji: "🌬️"),
        BreathingExercise(name: "Box Breathing", duration: 120, pattern: [4, 4, 4, 4], emoji: "📦"),
        BreathingExercise(name: "Deep Calm", duration: 180, pattern: [5, 5, 5], emoji: "🧘")
    ]
    
    struct BreathingExercise {
        let name: String
        let duration: Int // seconds
        let pattern: [Int] // inhale, hold, exhale, hold
        let emoji: String
    }
    
    init() {
        loadProgress()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserMessageReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let text = notification.object as? String {
                Task {
                    await self?.handleUserMessage(text)
                }
            }
        }
    }
    
    func handleUserMessage(_ text: String) async {
        let lowerText = text.lowercased()
        
        // Detect mood
        if lowerText.contains("great") || lowerText.contains("amazing") || lowerText.contains("wonderful") {
            currentMood = .great
        } else if lowerText.contains("good") || lowerText.contains("fine") || lowerText.contains("okay") {
            currentMood = .good
        } else if lowerText.contains("sad") || lowerText.contains("down") || lowerText.contains("low") {
            currentMood = .low
        } else if lowerText.contains("struggling") || lowerText.contains("difficult") || lowerText.contains("hard") {
            currentMood = .struggling
        }
        
        // Detect breathing exercise requests
        if lowerText.contains("breathing") || lowerText.contains("breathe") || lowerText.contains("calm") {
            await startBreathingExercise()
            return
        }
        
        // Detect meditation requests
        if lowerText.contains("meditate") || lowerText.contains("meditation") || lowerText.contains("mindful") {
            await startMeditationSession()
            return
        }
        
        // Generate supportive response
        let response = generateResponse(for: text)
        let emoji = getEmojiForResponse(response)
        
        await globalVoiceAssistant?.speak(response, emoji: emoji)
        
        // Show emoji
        NotificationCenter.default.post(
            name: NSNotification.Name("WellbeingEmoji"),
            object: emoji
        )
    }
    
    private func generateResponse(for text: String) -> String {
        let lowerText = text.lowercased()
        
        // Greetings
        if lowerText.contains("hello") || lowerText.contains("hi") || lowerText.contains("hey") {
            return "Hello! I'm here to support your mind wellbeing. How are you feeling today?"
        }
        
        // Mood responses
        if lowerText.contains("sad") || lowerText.contains("down") {
            return "I hear you. It's okay to feel this way. Would you like to try a breathing exercise together? It can help create a moment of calm."
        }
        
        if lowerText.contains("anxious") || lowerText.contains("worried") || lowerText.contains("stressed") {
            return "I understand that feeling. Let's take a moment to ground ourselves. Try taking three deep breaths with me."
        }
        
        if lowerText.contains("tired") || lowerText.contains("exhausted") {
            return "Rest is important for your wellbeing. Remember to be gentle with yourself. Would you like a short guided relaxation?"
        }
        
        if lowerText.contains("thank") {
            return "You're so welcome! I'm here whenever you need support. Remember, taking care of your mind is a journey, not a destination."
        }
        
        // Default supportive response
        return "I'm listening. Your feelings are valid. What would help you feel more grounded right now?"
    }
    
    private func getEmojiForResponse(_ response: String) -> String {
        if response.contains("breathing") || response.contains("breathe") {
            return "🌬️"
        }
        if response.contains("meditation") || response.contains("mindful") {
            return "🧘"
        }
        if response.contains("calm") || response.contains("relax") {
            return "🌊"
        }
        if response.contains("support") || response.contains("here") {
            return "💙"
        }
        return "🌱"
    }
    
    func startBreathingExercise() async {
        let exercise = breathingExercises.randomElement() ?? breathingExercises[0]
        breathingExerciseActive = true
        
        let message = "Let's do \(exercise.name). \(exercise.emoji) I'll guide you through it."
        await globalVoiceAssistant?.speak(message, emoji: exercise.emoji)
        
        // Guide through breathing pattern
        await guideBreathing(exercise)
    }
    
    private func guideBreathing(_ exercise: BreathingExercise) async {
        let pattern = exercise.pattern
        var cycle = 0
        
        while breathingExerciseActive && cycle < exercise.duration / 10 {
            // Inhale
            await globalVoiceAssistant?.speak("Breathe in... \(exercise.emoji)", emoji: exercise.emoji)
            try? await Task.sleep(nanoseconds: UInt64(pattern[0]) * 1_000_000_000)
            
            if pattern.count > 1 {
                // Hold
                await globalVoiceAssistant?.speak("Hold...", emoji: exercise.emoji)
                try? await Task.sleep(nanoseconds: UInt64(pattern[1]) * 1_000_000_000)
            }
            
            // Exhale
            await globalVoiceAssistant?.speak("Breathe out...", emoji: exercise.emoji)
            try? await Task.sleep(nanoseconds: UInt64(pattern.count > 2 ? pattern[2] : pattern[0]) * 1_000_000_000)
            
            if pattern.count > 3 {
                // Hold
                try? await Task.sleep(nanoseconds: UInt64(pattern[3]) * 1_000_000_000)
            }
            
            cycle += 1
        }
        
        breathingExerciseActive = false
        await globalVoiceAssistant?.speak("Great job! How do you feel now?", emoji: "🌱")
    }
    
    func startMeditationSession() async {
        sessionActive = true
        await globalVoiceAssistant?.speak("Let's take a moment for mindfulness. Find a comfortable position and close your eyes if you'd like.", emoji: "🧘")
        
        // Short guided meditation
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        await globalVoiceAssistant?.speak("Notice your breath, without trying to change it. Just observe.", emoji: "🌊")
        
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        await globalVoiceAssistant?.speak("If your mind wanders, that's okay. Gently bring your attention back to your breath.", emoji: "🌿")
        
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        await globalVoiceAssistant?.speak("Take a moment to notice how you feel. You've done something wonderful for your mind wellbeing.", emoji: "✨")
        
        sessionActive = false
        updateProgress()
    }
    
    private func updateProgress() {
        let today = Calendar.current.startOfDay(for: Date())
        weeklyProgress[today, default: 0] += 1
        
        // Check for daily streak
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        if weeklyProgress[yesterday, default: 0] > 0 {
            dailyStreak += 1
        } else {
            dailyStreak = 1
        }
        
        saveProgress()
    }
    
    private func saveProgress() {
        // Save to UserDefaults or file
        UserDefaults.standard.set(dailyStreak, forKey: "dailyStreak")
    }
    
    private func loadProgress() {
        dailyStreak = UserDefaults.standard.integer(forKey: "dailyStreak")
    }
}

// Global reference - will be set by SproutApp
var globalVoiceAssistant: VoiceAssistant?

