import SwiftUI

struct VoiceAssistantView: View {
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    
    var body: some View {
        VStack(spacing: 8) {
            // Always show transcription area
            VStack(spacing: 4) {
                // Status indicator
                HStack(spacing: 6) {
                    if voiceAssistant.isListening {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(voiceAssistant.isListening ? 1.0 : 0.3)
                        Text("Listening...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    } else if voiceAssistant.isSpeaking {
                        Image(systemName: "waveform")
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                        Text("Speaking...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                            .opacity(0.5)
                        Text("Ready")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(voiceAssistant.isListening ? Color.red.opacity(0.6) : 
                           voiceAssistant.isSpeaking ? Color.blue.opacity(0.6) : 
                           Color.black.opacity(0.4))
                .cornerRadius(12)
                
                // Transcription text - always visible
                if !voiceAssistant.currentMessage.isEmpty {
                    Text(voiceAssistant.currentMessage)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // Placeholder when no transcription
                    Text("Say something...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

