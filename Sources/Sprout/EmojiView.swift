import SwiftUI

struct EmojiView: View {
    @State private var currentEmoji: String = ""
    @State private var scale: CGFloat = 0.0
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var changeTimer: Timer?
    @State private var lastAudioLevel: Float = 0.0
    @State private var lastAudioIntensity: Float = 0.0
    
    // Mind wellbeing emojis - positive and supportive (round emojis only)
    let wellbeingEmojis = [
        "😊", "😄", "😃", "😁", "😆", "😍", "🥰", "😘",
        "🤗", "😉", "😋", "😎", "🤩", "🥳", "😇", "🙂",
        "😌", "😏", "💚", "💙", "💜", "❤️", "🧡", "💛",
        "✨", "🌟", "⭐", "💫", "🌈", "☀️", "🌙", "🦋"
    ]
    
    // Calming emojis for low energy states (round emojis only)
    let calmingEmojis = [
        "🌙", "😌", "😊", "💙", "💜", "✨", "🌟", "🦋",
        "😇", "🙂", "💚", "⭐", "💫", "🌈", "☀️", "🥰"
    ]
    
    // Energetic emojis for high energy (round emojis only)
    let energeticEmojis = [
        "☀️", "🌈", "⭐", "💫", "😄", "😃", "😁", "🤩",
        "🥳", "😍", "🥰", "✨", "🌟", "😊", "😎", "😘"
    ]
    
    // Too loud emojis (round emojis only)
    let tooLoudEmojis = ["😱", "😰", "😵", "😮", "😲", "🤭", "😳", "😨"]
    
    var body: some View {
        ZStack {
            if !currentEmoji.isEmpty {
                Text(currentEmoji)
                    .font(.system(size: 40))
                    .scaleEffect(scale * pulseScale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                    .animation(.easeInOut(duration: 0.3), value: scale)
                    .animation(.easeInOut(duration: 0.3), value: opacity)
                    .animation(.easeInOut(duration: 0.3), value: rotation)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowEmoji"))) { _ in
            showRandomEmoji()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AudioLevelChanged"))) { notification in
            if let level = notification.object as? Float {
                handleAudioLevel(level)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AudioIntensityChanged"))) { notification in
            if let intensity = notification.object as? Float {
                handleAudioIntensity(intensity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WellbeingEmoji"))) { notification in
            if let emoji = notification.object as? String {
                showSpecificEmoji(emoji)
            }
        }
    }
    
    func handleAudioLevel(_ level: Float) {
        lastAudioLevel = level
    }
    
    func handleAudioIntensity(_ intensity: Float) {
        lastAudioIntensity = intensity
        
        // Adjusted thresholds for loud environments
        // Higher thresholds since baseline noise is already high
        let loudThreshold = 0.85  // Increased from 0.7 for loud environments
        let energeticThreshold = 0.4  // Increased from 0.3
        let wellbeingThreshold = 0.2  // Increased from 0.15
        let calmingThreshold = 0.08  // Increased from 0.05
        
        // If level > loudThreshold, show "too loud" emojis
        if lastAudioLevel > loudThreshold {
            if currentEmoji.isEmpty || !tooLoudEmojis.contains(currentEmoji) {
                showEmoji(from: tooLoudEmojis)
            }
        }
        // If intensity > energeticThreshold, show energetic emojis
        else if intensity > energeticThreshold {
            if currentEmoji.isEmpty || !energeticEmojis.contains(currentEmoji) {
                showEmoji(from: energeticEmojis)
            }
        }
        // If intensity > wellbeingThreshold, show general wellbeing emojis
        else if intensity > wellbeingThreshold {
            if currentEmoji.isEmpty || !wellbeingEmojis.contains(currentEmoji) {
                showEmoji(from: wellbeingEmojis)
            }
        }
        // Low intensity - show calming emojis
        else if intensity > calmingThreshold {
            if currentEmoji.isEmpty || !calmingEmojis.contains(currentEmoji) {
                showEmoji(from: calmingEmojis)
            }
        }
    }
    
    func showRandomEmoji() {
        let emojiList: [String]
        // Adjusted thresholds for loud environments
        if lastAudioLevel > 0.85 {
            emojiList = tooLoudEmojis
        } else if lastAudioIntensity > 0.4 {
            emojiList = energeticEmojis
        } else if lastAudioIntensity > 0.2 {
            emojiList = wellbeingEmojis
        } else {
            emojiList = calmingEmojis
        }
        showEmoji(from: emojiList)
    }
    
    func showSpecificEmoji(_ emoji: String) {
        showEmoji(from: [emoji])
    }
    
    func showEmoji(from emojiList: [String]) {
        changeTimer?.invalidate()
        
        currentEmoji = emojiList.randomElement() ?? "😊"
        
        rotation = 0.0
        scale = 0.0
        opacity = 0.0
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
            rotation = 720.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
            
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                rotation = 1080.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            hideEmoji()
        }
    }
    
    func hideEmoji() {
        withAnimation(.easeOut(duration: 0.5)) {
            opacity = 0.0
            scale = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentEmoji = ""
            changeTimer?.invalidate()
        }
    }
}

