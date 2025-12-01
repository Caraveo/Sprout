import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var ollamaBaseURL: String {
        didSet {
            UserDefaults.standard.set(ollamaBaseURL, forKey: "ollamaBaseURL")
        }
    }
    
    @Published var ollamaModel: String {
        didSet {
            UserDefaults.standard.set(ollamaModel, forKey: "ollamaModel")
        }
    }
    
    @Published var useCloudAI: Bool {
        didSet {
            UserDefaults.standard.set(useCloudAI, forKey: "useCloudAI")
        }
    }
    
    @Published var cloudAPIKey: String {
        didSet {
            // Store securely in Keychain (simplified for now - use UserDefaults)
            UserDefaults.standard.set(cloudAPIKey, forKey: "cloudAPIKey")
        }
    }
    
    @Published var cloudProvider: CloudProvider {
        didSet {
            UserDefaults.standard.set(cloudProvider.rawValue, forKey: "cloudProvider")
        }
    }
    
    @Published var cloudModel: String {
        didSet {
            UserDefaults.standard.set(cloudModel, forKey: "cloudModel")
        }
    }
    
    @Published var cloudBaseURL: String {
        didSet {
            UserDefaults.standard.set(cloudBaseURL, forKey: "cloudBaseURL")
        }
    }
    
    @Published var voiceType: VoiceType {
        didSet {
            UserDefaults.standard.set(voiceType.rawValue, forKey: "voiceType")
        }
    }
    
    @Published var ollamaAllowRemote: Bool {
        didSet {
            UserDefaults.standard.set(ollamaAllowRemote, forKey: "ollamaAllowRemote")
        }
    }
    
    @Published var availableOllamaModels: [String] = []
    
    enum VoiceType: String, CaseIterable, Identifiable {
        case neutral = "neutral"
        case enthusiastic = "enthusiastic"
        case encouraging = "encouraging"
        case happy = "happy"
        case sad = "sad"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .neutral: return "Neutral"
            case .enthusiastic: return "Enthusiastic"
            case .encouraging: return "Encouraging"
            case .happy: return "Happy"
            case .sad: return "Sad"
            }
        }
        
        // Map to OpenVoice speaker styles
        var openVoiceSpeaker: String {
            switch self {
            case .neutral: return "default"
            case .enthusiastic: return "excited"
            case .encouraging: return "friendly"
            case .happy: return "cheerful"
            case .sad: return "sad"
            }
        }
    }
    
    enum CloudProvider: String, CaseIterable {
        case openai = "OpenAI"
        case anthropic = "Anthropic"
        case custom = "Custom API"
        
        var defaultBaseURL: String {
            switch self {
            case .openai: return "https://api.openai.com/v1"
            case .anthropic: return "https://api.anthropic.com/v1"
            case .custom: return "https://api.example.com/v1"
            }
        }
        
        var defaultModel: String {
            switch self {
            case .openai: return "gpt-4o-mini"
            case .anthropic: return "claude-3-5-sonnet-20241022"
            case .custom: return "custom-model"
            }
        }
    }
    
    private init() {
        // Load from UserDefaults
        ollamaBaseURL = UserDefaults.standard.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
        ollamaModel = UserDefaults.standard.string(forKey: "ollamaModel") ?? "llama3.2"
        useCloudAI = UserDefaults.standard.bool(forKey: "useCloudAI")
        cloudAPIKey = UserDefaults.standard.string(forKey: "cloudAPIKey") ?? ""
        
        // Initialize cloudProvider first
        let provider: CloudProvider
        if let providerRaw = UserDefaults.standard.string(forKey: "cloudProvider"),
           let parsedProvider = CloudProvider(rawValue: providerRaw) {
            provider = parsedProvider
        } else {
            provider = .openai
        }
        cloudProvider = provider
        
        // Now we can use provider for defaults
        cloudModel = UserDefaults.standard.string(forKey: "cloudModel") ?? provider.defaultModel
        cloudBaseURL = UserDefaults.standard.string(forKey: "cloudBaseURL") ?? provider.defaultBaseURL
        
        // Load voice type
        if let voiceTypeRaw = UserDefaults.standard.string(forKey: "voiceType"),
           let parsedVoiceType = VoiceType(rawValue: voiceTypeRaw) {
            voiceType = parsedVoiceType
        } else {
            voiceType = .neutral
        }
        
        // Load remote access setting
        ollamaAllowRemote = UserDefaults.standard.bool(forKey: "ollamaAllowRemote")
    }
    
    func resetToDefaults() {
        ollamaBaseURL = "http://localhost:11434"
        ollamaModel = "llama3.2"
        useCloudAI = false
        cloudAPIKey = ""
        cloudProvider = .openai
        cloudModel = cloudProvider.defaultModel
        cloudBaseURL = cloudProvider.defaultBaseURL
        voiceType = .neutral
        ollamaAllowRemote = false
    }
    
    func refreshOllamaModels() async {
        let service = OllamaService(baseURL: ollamaBaseURL, model: ollamaModel)
        let models = await service.listModels()
        await MainActor.run {
            self.availableOllamaModels = models
            // If current model is not in list, keep it (might be downloading)
            if !models.isEmpty && !models.contains(ollamaModel) {
                print("⚠️ Current model '\(ollamaModel)' not in available models list")
            }
        }
    }
}

