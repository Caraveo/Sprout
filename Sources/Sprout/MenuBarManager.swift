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
        popover.contentSize = NSSize(width: 320, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(voiceAssistant)
                .environmentObject(wellbeingCoach)
                .frame(width: 320, height: 500)
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
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("🌱 Sprout")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Mood section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Current Mood")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        ForEach(WellbeingCoach.Mood.allCases, id: \.self) { mood in
                            Button(action: {
                                wellbeingCoach.currentMood = mood
                            }) {
                                VStack(spacing: 6) {
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
                .padding(.vertical, 4)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Quick actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
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
                .padding(.vertical, 4)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Progress section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(wellbeingCoach.dailyStreak)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Day Streak")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
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
                .padding(.vertical, 4)
                
                // View full log button
                Divider()
                    .padding(.vertical, 4)
                
                Button(action: {
                    // Open conversation log in a new window
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                        styleMask: [.titled, .closable, .resizable],
                        backing: .buffered,
                        defer: false
                    )
                    window.title = "Conversation Log"
                    window.contentView = NSHostingView(
                        rootView: ConversationLogView()
                            .environmentObject(voiceAssistant)
                    )
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                }) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 14))
                        Text("View Full Conversation Log")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                
                // Recent conversations preview
                if !voiceAssistant.conversationHistory.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(voiceAssistant.conversationHistory.suffix(2)) { message in
                                MenuBarConversationBubble(message: message)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                
                Spacer()
            }
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 500)
    }
}

struct MenuBarActionButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(color.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MenuBarConversationBubble: View {
    let message: VoiceAssistant.ConversationMessage
    @State private var showAnalysis = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                if let emoji = message.emoji {
                    Text(emoji)
                        .font(.system(size: 16))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Analysis preview
            if let analysis = message.analysis, !analysis.isEmpty {
                Button(action: {
                    showAnalysis.toggle()
                }) {
                    HStack {
                        Text("💭 Analysis")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Image(systemName: showAnalysis ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 2)
                
                if showAnalysis {
                    Text(analysis)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 4)
                }
            }
        }
        .padding(12)
        .background(message.isUser ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
        .cornerRadius(8)
    }
}

