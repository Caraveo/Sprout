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
        popover.contentSize = NSSize(width: 340, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(voiceAssistant)
                .environmentObject(wellbeingCoach)
                .frame(width: 340, height: 520)
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
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with gradient background
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.3), Color.accentColor.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            Text("🌱")
                                .font(.system(size: 18))
                        }
                        Text("Sprout")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green, Color.accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    Spacer()
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.08), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Divider()
                    .padding(.vertical, 4)
                    .padding(.horizontal, 20)
                
                // Mood section with beautiful cards
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.pink)
                        Text("Current Mood")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 4)
                    
                    HStack(spacing: 12) {
                        ForEach(WellbeingCoach.Mood.allCases, id: \.self) { mood in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    wellbeingCoach.currentMood = mood
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Text(mood.emoji)
                                        .font(.system(size: 26))
                                    Text(mood.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                .frame(width: 56, height: 56)
                                .background(
                                    Group {
                                        if wellbeingCoach.currentMood == mood {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.secondary.opacity(0.08))
                                        }
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(wellbeingCoach.currentMood == mood ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                
                // Quick actions with enhanced styling
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Quick Actions")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 4)
                    
                    VStack(spacing: 10) {
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
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                
                // Progress section with beautiful cards
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("Your Progress")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 4)
                    
                    HStack(spacing: 12) {
                        // Streak card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(wellbeingCoach.dailyStreak)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Day Streak")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.15), Color.red.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Weekly card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(wellbeingCoach.weeklyProgress.values.reduce(0, +))")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("This Week")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // View full log button
                Divider()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 10) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                            Text("Settings")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.12))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.12))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                
                // Recent conversations preview
                if !voiceAssistant.conversationHistory.isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 12) {
                            ForEach(voiceAssistant.conversationHistory.suffix(2)) { message in
                                MenuBarConversationBubble(message: message)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .frame(width: 340, height: 520)
    }
}

struct MenuBarActionButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isHovered ? 0.3 : 0.2),
                                color.opacity(isHovered ? 0.25 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 6 : 3, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
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

