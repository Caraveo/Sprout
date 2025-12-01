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
        popover.contentSize = NSSize(width: 360, height: 560)
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .aqua)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(voiceAssistant)
                .environmentObject(wellbeingCoach)
                .frame(width: 360, height: 560)
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
            VStack(spacing: 0) {
                // Beautiful header with gradient
                VStack(spacing: 8) {
                    HStack {
                        Text("🌱")
                            .font(.system(size: 32))
                        Text("Sprout")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Spacer()
                    }
                    Text("Your mind wellbeing companion")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.05), Color.mint.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Divider()
                    .padding(.vertical, 0)
                
                // Mood section - beautiful cards
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current Mood")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 10) {
                        ForEach(WellbeingCoach.Mood.allCases, id: \.self) { mood in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    wellbeingCoach.currentMood = mood
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Text(mood.emoji)
                                        .font(.system(size: 28))
                                    Text(mood.rawValue)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                .frame(width: 56, height: 56)
                                .background(
                                    Group {
                                        if wellbeingCoach.currentMood == mood {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.secondary.opacity(0.08))
                                        }
                                    }
                                )
                                .shadow(color: wellbeingCoach.currentMood == mood ? Color.green.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                Divider()
                    .padding(.vertical, 0)
                
                // Quick actions - beautiful gradient buttons
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Quick Actions")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    VStack(spacing: 10) {
                        MenuBarActionButton(
                            title: voiceAssistant.isListening ? "Stop Listening" : "Start Listening",
                            emoji: voiceAssistant.isListening ? "⏸️" : "🎤",
                            color: voiceAssistant.isListening ? .red : .green,
                            isActive: voiceAssistant.isListening
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
                            color: .blue,
                            isActive: false
                        ) {
                            Task {
                                await wellbeingCoach.startBreathingExercise()
                            }
                        }
                        
                        MenuBarActionButton(
                            title: "Meditation",
                            emoji: "🧘",
                            color: .purple,
                            isActive: false
                        ) {
                            Task {
                                await wellbeingCoach.startMeditationSession()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                Divider()
                    .padding(.vertical, 0)
                
                // Progress section - beautiful stat cards
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Progress")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        // Streak card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("🔥")
                                    .font(.system(size: 16))
                                Spacer()
                            }
                            Text("\(wellbeingCoach.dailyStreak)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Day Streak")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Weekly card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("📊")
                                    .font(.system(size: 16))
                                Spacer()
                            }
                            Text("\(wellbeingCoach.weeklyProgress.values.reduce(0, +))")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("This Week")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // View full log button - beautiful gradient
                Divider()
                    .padding(.vertical, 0)
                
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
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Text("View Full Conversation Log")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Recent conversations preview
                if !voiceAssistant.conversationHistory.isEmpty {
                    Divider()
                        .padding(.vertical, 0)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Conversations")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        VStack(spacing: 10) {
                            ForEach(voiceAssistant.conversationHistory.suffix(2)) { message in
                                MenuBarConversationBubble(message: message)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                
                Spacer(minLength: 20)
            }
        }
        .frame(width: 360, height: 560)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct MenuBarActionButton: View {
    let title: String
    let emoji: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                if isActive {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isActive ?
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [color.opacity(0.12), color.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isActive ? color.opacity(0.4) : color.opacity(0.15), lineWidth: isActive ? 1.5 : 1)
                    )
            )
            .shadow(color: isActive ? color.opacity(0.2) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MenuBarConversationBubble: View {
    let message: VoiceAssistant.ConversationMessage
    @State private var showAnalysis = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                if let emoji = message.emoji {
                    Text(emoji)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.text)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Analysis preview - beautiful expandable
            if let analysis = message.analysis, !analysis.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAnalysis.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 9, weight: .medium))
                        Text("Analysis")
                            .font(.system(size: 10, weight: .medium))
                        Image(systemName: showAnalysis ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 2)
                
                if showAnalysis {
                    Text(analysis)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 6)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    message.isUser ?
                    LinearGradient(
                        colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            message.isUser ? Color.blue.opacity(0.2) : Color.green.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}

