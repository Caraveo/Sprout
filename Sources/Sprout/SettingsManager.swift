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
        case angry = "angry"
        case terrified = "terrified"
        case shouting = "shouting"
        case whispering = "whispering"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .neutral: return "Neutral"
            case .enthusiastic: return "Enthusiastic"
            case .encouraging: return "Encouraging"
            case .happy: return "Happy"
            case .sad: return "Sad"
            case .angry: return "Angry"
            case .terrified: return "Terrified"
            case .shouting: return "Shouting"
            case .whispering: return "Whispering"
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
            case .angry: return "angry"
            case .terrified: return "terrified"
            case .shouting: return "shouting"
            case .whispering: return "whispering"
            }
        }
    }
    
    // Temporary voice style for testing (doesn't save to settings)
    @Published var testVoiceStyle: VoiceType? = nil
    
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
            
            if !models.isEmpty {
                // Auto-select the best model if current model is not available or if no model is set
                if !models.contains(ollamaModel) || ollamaModel.isEmpty {
                    let bestModel = selectBestModel(from: models)
                    print("🎯 Auto-selected best model: \(bestModel)")
                    self.ollamaModel = bestModel
                }
            }
        }
    }
    
    private func selectBestModel(from models: [String]) -> String {
        // Model priority: larger/newer models are generally better
        // Priority order: llama3.2 > llama3.1 > llama3 > llama2 > mistral > others
        
        let modelPriority: [String: Int] = [
            "llama3.2": 100,
            "llama3.1": 90,
            "llama3": 80,
            "llama2": 70,
            "mistral": 60,
            "mixtral": 65,
            "phi": 50,
            "gemma": 55,
            "qwen": 45
        ]
        
        // Find the model with highest priority
        var bestModel: String? = nil
        var bestPriority = -1
        
        for model in models {
            let lowerModel = model.lowercased()
            var priority = 0
            
            // Check for priority matches
            for (key, value) in modelPriority {
                if lowerModel.contains(key) {
                    priority = max(priority, value)
                }
            }
            
            // Boost priority for larger models (indicated by numbers or size indicators)
            if lowerModel.contains("70b") || lowerModel.contains("65b") {
                priority += 20
            } else if lowerModel.contains("13b") || lowerModel.contains("8b") {
                priority += 10
            } else if lowerModel.contains("7b") || lowerModel.contains("3b") {
                priority += 5
            }
            
            // Prefer newer versions (higher numbers)
            if let versionMatch = lowerModel.range(of: #"\d+\.\d+"#, options: .regularExpression) {
                let version = String(lowerModel[versionMatch])
                if let versionNum = Double(version) {
                    priority += Int(versionNum * 2)
                }
            }
            
            if priority > bestPriority {
                bestPriority = priority
                bestModel = model
            }
        }
        
        // Fallback: if no priority match, prefer longer names (usually more specific)
        if bestModel == nil {
            bestModel = models.max(by: { $0.count < $1.count })
        }
        
        return bestModel ?? models.first ?? "llama3.2"
    }
}

