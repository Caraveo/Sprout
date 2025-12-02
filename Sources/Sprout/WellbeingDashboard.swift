import SwiftUI

struct WellbeingDashboard: View {
    @EnvironmentObject var wellbeingCoach: WellbeingCoach
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mood section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Mood")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        ForEach(WellbeingCoach.Mood.allCases, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: wellbeingCoach.currentMood == mood
                            ) {
                                wellbeingCoach.currentMood = mood
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                // Quick actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Breathing",
                            emoji: "😌",
                            color: .blue
                        ) {
                            Task {
                                await wellbeingCoach.startBreathingExercise()
                            }
                        }
                        
                        ActionButton(
                            title: "Meditation",
                            emoji: "😇",
                            color: .purple
                        ) {
                            Task {
                                await wellbeingCoach.startMeditationSession()
                            }
                        }
                        
                        ActionButton(
                            title: voiceAssistant.isListening ? "Stop" : "Talk",
                            emoji: voiceAssistant.isListening ? "⏸️" : "😊",
                            color: voiceAssistant.isListening ? .red : .green
                        ) {
                            if voiceAssistant.isListening {
                                voiceAssistant.stopListening()
                            } else {
                                voiceAssistant.startListening()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                // Progress section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Progress")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(wellbeingCoach.dailyStreak)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("Day Streak")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(wellbeingCoach.weeklyProgress.values.reduce(0, +))")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("This Week")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                // Recent conversations
                if !voiceAssistant.conversationHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        ForEach(voiceAssistant.conversationHistory.suffix(3)) { message in
                            ConversationBubble(message: message)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color.clear)
    }
}

struct MoodButton: View {
    let mood: WellbeingCoach.Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 24))
                Text(mood.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            .background(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActionButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConversationBubble: View {
    let message: VoiceAssistant.ConversationMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let emoji = message.emoji {
                Text(emoji)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message.text)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(8)
        .background(message.isUser ? Color.blue.opacity(0.3) : Color.green.opacity(0.3))
        .cornerRadius(8)
    }
}

