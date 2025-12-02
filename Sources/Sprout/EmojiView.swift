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
        
        // If level > 0.7, show "too loud" emojis
        if lastAudioLevel > 0.7 {
            if currentEmoji.isEmpty || !tooLoudEmojis.contains(currentEmoji) {
                showEmoji(from: tooLoudEmojis)
            }
        }
        // If intensity > 0.3, show energetic emojis
        else if intensity > 0.3 {
            if currentEmoji.isEmpty || !energeticEmojis.contains(currentEmoji) {
                showEmoji(from: energeticEmojis)
            }
        }
        // If intensity > 0.15, show general wellbeing emojis
        else if intensity > 0.15 {
            if currentEmoji.isEmpty || !wellbeingEmojis.contains(currentEmoji) {
                showEmoji(from: wellbeingEmojis)
            }
        }
        // Low intensity - show calming emojis
        else if intensity > 0.05 {
            if currentEmoji.isEmpty || !calmingEmojis.contains(currentEmoji) {
                showEmoji(from: calmingEmojis)
            }
        }
    }
    
    func showRandomEmoji() {
        let emojiList: [String]
        if lastAudioLevel > 0.7 {
            emojiList = tooLoudEmojis
        } else if lastAudioIntensity > 0.3 {
            emojiList = energeticEmojis
        } else if lastAudioIntensity > 0.15 {
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

