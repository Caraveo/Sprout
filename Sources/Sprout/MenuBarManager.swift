import AppKit
import SwiftUI

// Global reference for popover resizing
var globalMenuBarManager: MenuBarManager?

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    var popover: NSPopover? // Made internal for access
    
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
        
        // Create popover with menu content - will resize dynamically
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 520)
        popover.behavior = .transient
        let hostingController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(voiceAssistant)
                .environmentObject(wellbeingCoach)
        )
        popover.contentViewController = hostingController
        self.popover = popover
        
        // Store reference for resizing
        globalMenuBarManager = self
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
    @State private var currentView: MenuViewType = .main
    
    enum MenuViewType {
        case main
        case settings
    }
    
    var body: some View {
        Group {
            if currentView == .settings {
                MenuBarSettingsView(currentView: $currentView)
                    .frame(width: 600, height: 750)
                    .onAppear {
                        globalMenuBarManager?.popover?.contentSize = NSSize(width: 600, height: 750)
                    }
            } else {
                MenuBarMainView(
                    voiceAssistant: voiceAssistant,
                    wellbeingCoach: wellbeingCoach,
                    currentView: $currentView
                )
                .frame(width: 340, height: 520)
                .onAppear {
                    globalMenuBarManager?.popover?.contentSize = NSSize(width: 340, height: 520)
                }
            }
        }
        .onChange(of: currentView) { newView in
            // Resize popover when view changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                globalMenuBarManager?.popover?.contentSize = newView == .settings ? NSSize(width: 600, height: 750) : NSSize(width: 340, height: 520)
            }
        }
    }
}

struct MenuBarMainView: View {
    @ObservedObject var voiceAssistant: VoiceAssistant
    @ObservedObject var wellbeingCoach: WellbeingCoach
    @Binding var currentView: MenuBarView.MenuViewType
    
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
                            Text("😊")
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
                    Button(action: { currentView = .settings }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color(NSColor.controlBackgroundColor))
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
                                                .shadow(color: Color(NSColor.shadowColor).opacity(0.2), radius: 4, x: 0, y: 2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(NSColor.controlBackgroundColor))
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
                            emoji: voiceAssistant.isListening ? "⏸️" : "😊",
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
                            emoji: "😌",
                            color: .blue
                        ) {
                            Task {
                                await wellbeingCoach.startBreathingExercise()
                            }
                        }
                        
                        MenuBarActionButton(
                            title: "Meditation",
                            emoji: "😇",
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
                        currentView = .settings
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
    }
}

struct MenuBarSettingsView: View {
    @Binding var currentView: MenuBarView.MenuViewType
    @StateObject private var settings = SettingsManager.shared
    @State private var showingAPIKey = false
    @State private var testConnectionStatus: String? = nil
    @State private var testingVoiceStyle: SettingsManager.VoiceType? = nil
    @State private var voiceTestStatus: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: { currentView = .main }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                    Text("Settings")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Invisible spacer for balance
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                    Text("Back")
                        .font(.system(size: 13, weight: .medium))
                }
                .opacity(0)
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Use the existing SettingsView content
            ScrollView {
                VStack(spacing: 24) {
                    // Local AI (Ollama) Section
                    SettingsSection(title: "Local AI (Ollama)", icon: "cpu") {
                        VStack(spacing: 16) {
                            Toggle(isOn: $settings.ollamaAllowRemote) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Allow Remote Access")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Enable to use Ollama from other devices on your network")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            SettingsRow(label: "Base URL") {
                                TextField("http://localhost:11434", text: $settings.ollamaBaseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .help(settings.ollamaAllowRemote ? "Use your computer's IP address for remote access (e.g., http://192.168.1.100:11434)" : "Local Ollama instance URL")
                            }
                            
                            SettingsRow(label: "Model") {
                                if settings.availableOllamaModels.isEmpty {
                                    TextField("llama3.2", text: $settings.ollamaModel)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Picker("", selection: $settings.ollamaModel) {
                                            ForEach(settings.availableOllamaModels, id: \.self) { model in
                                                Text(model).tag(model)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        
                                        if settings.availableOllamaModels.count > 1 {
                                            Button(action: {
                                                let bestModel = settings.selectBestModel()
                                                settings.ollamaModel = bestModel
                                                print("🎯 Manually selected best model: \(bestModel)")
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "sparkles")
                                                        .font(.system(size: 9))
                                                    Text("Auto-select Best")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(.blue)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .help("Automatically select the best available model")
                                        }
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: refreshOllamaModels) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Refresh Models")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: testOllamaConnection) {
                                    HStack {
                                        Image(systemName: "network")
                                        Text("Test Connection")
                                        if let status = testConnectionStatus {
                                            Text(status)
                                                .foregroundColor(status.contains("✅") ? .green : .red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if !settings.availableOllamaModels.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(settings.availableOllamaModels.count) model(s) available")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    // Show model list
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(settings.availableOllamaModels, id: \.self) { model in
                                                Text(model)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        settings.ollamaModel == model ?
                                                        Color.accentColor.opacity(0.2) :
                                                        Color(NSColor.controlBackgroundColor)
                                                    )
                                                    .cornerRadius(6)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(
                                                                settings.ollamaModel == model ?
                                                                Color.accentColor.opacity(0.5) :
                                                                Color.clear,
                                                                lineWidth: 1
                                                            )
                                                    )
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Voice Type Section
                    SettingsSection(title: "Voice Type / Emotion", icon: "waveform") {
                        VStack(spacing: 16) {
                            Picker("Voice Type", selection: $settings.voiceType) {
                                ForEach(SettingsManager.VoiceType.allCases) { voiceType in
                                    Text(voiceType.displayName).tag(voiceType)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Choose how Sprout's voice sounds: \(settings.voiceType.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Test Voice Styles Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Test Voice Styles")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Try different voice styles without changing your saved setting")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Grid of voice style test buttons
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(SettingsManager.VoiceType.allCases) { voiceType in
                                        Button(action: {
                                            testVoiceStyle(voiceType)
                                        }) {
                                            VStack(spacing: 4) {
                                                Text(voiceType.displayName)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(
                                                        testingVoiceStyle == voiceType ?
                                                        Color(NSColor.labelColor) :
                                                        .primary
                                                    )
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                testingVoiceStyle == voiceType ?
                                                Color.accentColor :
                                                Color(NSColor.controlBackgroundColor)
                                            )
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                if let status = voiceTestStatus {
                                    Text(status)
                                        .font(.caption)
                                        .foregroundColor(status.contains("✅") ? .green : .secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                if settings.testVoiceStyle != nil {
                                    Button(action: {
                                        settings.testVoiceStyle = nil
                                        testingVoiceStyle = nil
                                        voiceTestStatus = "✅ Test mode cleared - using saved voice style"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            voiceTestStatus = nil
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("Clear Test Mode")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Cloud AI Section
                    SettingsSection(title: "Cloud AI", icon: "cloud.fill") {
                        VStack(spacing: 16) {
                            Toggle(isOn: $settings.useCloudAI) {
                                Text("Enable Cloud AI")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            
                            if settings.useCloudAI {
                                VStack(spacing: 16) {
                                    SettingsRow(label: "Provider") {
                                        Picker("", selection: $settings.cloudProvider) {
                                            ForEach(SettingsManager.CloudProvider.allCases, id: \.self) { provider in
                                                Text(provider.rawValue).tag(provider)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .onChange(of: settings.cloudProvider) { newProvider in
                                            settings.cloudModel = newProvider.defaultModel
                                            settings.cloudBaseURL = newProvider.defaultBaseURL
                                        }
                                    }
                                    
                                    SettingsRow(label: "Base URL") {
                                        TextField(settings.cloudProvider.defaultBaseURL, text: $settings.cloudBaseURL)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    SettingsRow(label: "Model") {
                                        TextField(settings.cloudProvider.defaultModel, text: $settings.cloudModel)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    SettingsRow(label: "API Key") {
                                        HStack {
                                            if showingAPIKey {
                                                TextField("Enter API key", text: $settings.cloudAPIKey)
                                                    .textFieldStyle(.roundedBorder)
                                            } else {
                                                SecureField("Enter API key", text: $settings.cloudAPIKey)
                                                    .textFieldStyle(.roundedBorder)
                                            }
                                            Button(action: { showingAPIKey.toggle() }) {
                                                Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    
                                    Button(action: testCloudConnection) {
                                        HStack {
                                            Image(systemName: "network")
                                            Text("Test Cloud Connection")
                                            if let status = testConnectionStatus {
                                                Text(status)
                                                    .foregroundColor(status.contains("✅") ? .green : .red)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(settings.cloudAPIKey.isEmpty)
                                }
                                .padding(.top, 8)
                                .padding(.leading, 16)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: resetSettings) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Defaults")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(24)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Refresh models when settings view appears
            Task {
                await settings.refreshOllamaModels()
            }
        }
    }
    
    private func testOllamaConnection() {
        testConnectionStatus = "Testing..."
        Task {
            let service = OllamaService(baseURL: settings.ollamaBaseURL, model: settings.ollamaModel)
            let available = await service.checkAvailability()
            await MainActor.run {
                testConnectionStatus = available ? "✅ Connected" : "❌ Connection failed"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    testConnectionStatus = nil
                }
            }
        }
    }
    
    private func refreshOllamaModels() {
        Task {
            await settings.refreshOllamaModels()
            testOllamaConnection()
        }
    }
    
    private func testCloudConnection() {
        testConnectionStatus = "Testing..."
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                testConnectionStatus = "✅ Connected"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    testConnectionStatus = nil
                }
            }
        }
    }
    
    private func resetSettings() {
        settings.resetToDefaults()
    }
    
    private func testVoiceStyle(_ voiceType: SettingsManager.VoiceType) {
        testingVoiceStyle = voiceType
        settings.testVoiceStyle = voiceType
        voiceTestStatus = "Testing \(voiceType.displayName)..."
        
        Task {
            if let voiceAssistant = globalVoiceAssistant {
                let testText = "Hello Seedling! This is how I sound with \(voiceType.displayName.lowercased()) voice."
                await voiceAssistant.speak(testText, voiceStyle: voiceType)
                
                await MainActor.run {
                    voiceTestStatus = "✅ Tested \(voiceType.displayName) - This style will be used until you change it or clear test mode"
                }
            } else {
                await MainActor.run {
                    voiceTestStatus = "❌ Voice assistant not available. Please restart the app."
                }
            }
        }
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
        .background(message.isUser ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
        .cornerRadius(8)
    }
}

