import AppKit
import SwiftUI

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    @Published var isMenuVisible = false
    
    func setupMenuBar(voiceAssistant: VoiceAssistant, wellbeingCoach: WellbeingCoach) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else { return }
        
        // Set icon
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "Sprout")
            button.image?.isTemplate = true
            button.action = #selector(toggleMenu)
            button.target = self
        }
        
        // Create popover with menu content
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(voiceAssistant)
                .environmentObject(wellbeingCoach)
        )
        self.popover = popover
    }
    
    @objc func toggleMenu() {
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                isMenuVisible = false
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                isMenuVisible = true
            }
        }
    }
    
    func closeMenu() {
        popover?.performClose(nil)
        isMenuVisible = false
    }
}

struct MenuBarView: View {
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    @EnvironmentObject var wellbeingCoach: WellbeingCoach
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("🌱 Sprout")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
                
                Divider()
                
                // Mood section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Mood")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(WellbeingCoach.Mood.allCases, id: \.self) { mood in
                            Button(action: {
                                wellbeingCoach.currentMood = mood
                            }) {
                                VStack(spacing: 4) {
                                    Text(mood.emoji)
                                        .font(.system(size: 24))
                                    Text(mood.rawValue)
                                        .font(.system(size: 10))
                                        .foregroundColor(.primary)
                                }
                                .frame(width: 50, height: 50)
                                .background(wellbeingCoach.currentMood == mood ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Divider()
                
                // Quick actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        MenuBarActionButton(
                            title: voiceAssistant.isListening ? "Stop Listening" : "Start Listening",
                            emoji: voiceAssistant.isListening ? "⏸️" : "🎤",
                            color: voiceAssistant.isListening ? .red : .green
                        ) {
                            if voiceAssistant.isListening {
                                voiceAssistant.stopListening()
                            } else {
                                voiceAssistant.startListening()
                            }
                        }
                        
                        MenuBarActionButton(
                            title: "Breathing Exercise",
                            emoji: "🌬️",
                            color: .blue
                        ) {
                            Task {
                                await wellbeingCoach.startBreathingExercise()
                            }
                        }
                        
                        MenuBarActionButton(
                            title: "Meditation",
                            emoji: "🧘",
                            color: .purple
                        ) {
                            Task {
                                await wellbeingCoach.startMeditationSession()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Divider()
                
                // Progress section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(wellbeingCoach.dailyStreak)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Day Streak")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(wellbeingCoach.weeklyProgress.values.reduce(0, +))")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            Text("This Week")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Recent conversations
                if !voiceAssistant.conversationHistory.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ForEach(voiceAssistant.conversationHistory.suffix(3)) { message in
                            MenuBarConversationBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .padding(.bottom, 12)
        }
        .frame(width: 300, height: 400)
    }
}

struct MenuBarActionButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(color.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MenuBarConversationBubble: View {
    let message: VoiceAssistant.ConversationMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let emoji = message.emoji {
                Text(emoji)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message.text)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(message.isUser ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
        .cornerRadius(6)
    }
}

