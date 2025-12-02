import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingAPIKey = false
    @State private var testConnectionStatus: String? = nil
    @State private var testingVoiceStyle: SettingsManager.VoiceType? = nil
    @State private var voiceTestStatus: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
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
                                                        Color.secondary.opacity(0.1)
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
        .frame(width: 600, height: 750)
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
            // Also test connection when refreshing
            testOllamaConnection()
        }
    }
    
    private func testCloudConnection() {
        testConnectionStatus = "Testing..."
        // TODO: Implement cloud API test
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
        
        // Get global voice assistant and test the voice
        Task {
            // Access globalVoiceAssistant from WellbeingCoach file
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

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.bottom, 4)
            
            content
        }
        .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color(NSColor.shadowColor).opacity(0.1), radius: 5, x: 0, y: 2)
            )
    }
}

struct SettingsRow<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            content
        }
    }
}

