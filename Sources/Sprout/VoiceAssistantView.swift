import SwiftUI

struct VoiceAssistantView: View {
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    @State private var showTranscription = false
    @State private var hideTimer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            // Status indicator - always visible when active
            if voiceAssistant.isListening || voiceAssistant.isSpeaking {
                HStack(spacing: 6) {
                    if voiceAssistant.isListening {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
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
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(voiceAssistant.isListening ? Color.red.opacity(0.6) : Color.blue.opacity(0.6))
                .cornerRadius(12)
            }
            
            // Transcription text - show/hide with animation
            if showTranscription && !voiceAssistant.currentMessage.isEmpty {
                Text(voiceAssistant.currentMessage)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 8)
        .onChange(of: voiceAssistant.currentMessage) { newMessage in
            // Show transcription when message appears
            if !newMessage.isEmpty {
                withAnimation(.easeIn(duration: 0.3)) {
                    showTranscription = true
                }
                
                // Reset hide timer
                hideTimer?.invalidate()
                
                // Hide after 3 seconds of no updates
                hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self?.showTranscription = false
                        }
                    }
                }
            } else {
                // Hide immediately when message clears
                withAnimation(.easeOut(duration: 0.5)) {
                    showTranscription = false
                }
                hideTimer?.invalidate()
            }
        }
        .onDisappear {
            hideTimer?.invalidate()
        }
    }
}

