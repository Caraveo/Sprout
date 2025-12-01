import SwiftUI

struct VoiceAssistantView: View {
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    
    var body: some View {
        VStack(spacing: 8) {
            // Listening indicator
            if voiceAssistant.isListening {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(voiceAssistant.isListening ? 1.0 : 0.3)
                    Text("Listening...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            }
            
            // Current message being transcribed
            if !voiceAssistant.currentMessage.isEmpty {
                Text(voiceAssistant.currentMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .lineLimit(2)
            }
            
            // Speaking indicator
            if voiceAssistant.isSpeaking {
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Text("Speaking...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.7))
                .cornerRadius(20)
            }
        }
    }
}

