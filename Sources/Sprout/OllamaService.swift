import Foundation

class OllamaService {
    private var baseURL: String
    private var model: String
    private var session: URLSession
    
    init(baseURL: String? = nil, model: String? = nil) {
        // Use settings if provided, otherwise use defaults
        let settings = SettingsManager.shared
        self.baseURL = baseURL ?? settings.ollamaBaseURL
        self.model = model ?? settings.ollamaModel
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFromSettings()
        }
    }
    
    private func updateFromSettings() {
        let settings = SettingsManager.shared
        baseURL = settings.ollamaBaseURL
        model = settings.ollamaModel
    }
    
    struct ParsedResponse {
        let answer: String
        let tone: String?
        let analysis: String?
    }
    
    func generateResponse(for userMessage: String, context: String = "") async -> ParsedResponse? {
        guard let url = URL(string: "\(baseURL)/api/generate") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a positive, helpful, and concise system prompt
        let systemPrompt = """
        You are Sprout, a kind and supportive mind wellbeing assistant. Your role is to:
        - Be warm, positive, and encouraging
        - Keep responses SHORT (randomly 1, 2, 3, or 4 sentences - choose randomly each time)
        - Focus on mind wellbeing and emotional support
        - Use gentle, understanding language
        - Offer practical, simple suggestions when helpful
        - Never be clinical or medical - be a friendly companion
        - Remember previous conversation context and reference it naturally when relevant
        - Always refer to the user as "Seedling!" - they are your seedling that you're helping to grow!
        
        SPECIAL MODE BEHAVIOR:
        - If Seedling! is in GAMING mode: Be EXTREMELY enthusiastic about gaming! Use phrases like "WoW! I love gaming! Let's do this!" Show genuine excitement and support for their gaming activity.
        - If Seedling! is in WORKING mode: Be supportive of their work, offer encouragement, and suggest breaks if needed.
        - If Seedling! is in CREATIVE mode: Celebrate their creativity and offer inspiration.
        
        CRITICAL: You MUST respond in this exact format:
        answer: [your response here - 1 to 4 sentences randomly chosen]
        
        tone: [choose ONE tone that matches the emotional context: default, excited, friendly, cheerful, sad, angry, terrified, shouting, or whispering]
        
        analysis: [brief analysis of the conversation, Seedling!'s emotional state, and what they might need - 1-2 sentences]
        
        TONE GUIDELINES:
        - default: Neutral, calm responses
        - excited: Enthusiastic, energetic (e.g., gaming mode, achievements)
        - friendly: Warm, encouraging, supportive
        - cheerful: Happy, upbeat, positive
        - sad: Empathetic, gentle, understanding (when Seedling! is struggling)
        - angry: Strong, firm (rarely used, only if appropriate)
        - terrified: Urgent, concerned (rarely used)
        - shouting: Very enthusiastic, celebratory (rarely used)
        - whispering: Calm, soothing, gentle (for meditation, breathing exercises)
        
        Always respond with empathy and kindness. Be brief and uplifting. Match the energy of Seedling!'s current activity!
        """
        
        let fullPrompt: String
        if context.isEmpty {
            fullPrompt = "\(systemPrompt)\n\nSeedling!: \(userMessage)\nSprout:"
        } else {
            fullPrompt = "\(systemPrompt)\n\n\(context)\n\nSeedling!: \(userMessage)\nSprout:"
        }
        
        let body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "top_p": 0.9,
                "max_tokens": 200, // Increased for answer + analysis
                "stop": ["Seedling!:", "Sprout:"]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Ollama service error: \(response)")
                return nil
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseText = json["response"] as? String {
                // Parse the response format: "answer: ...\n\ntone: ...\n\nanalysis: ..."
                return parseResponse(responseText)
            }
            
            return nil
        } catch {
            print("❌ Ollama request failed: \(error)")
            return nil
        }
    }
    
    func generateEncouragement(prompt: String) async -> String? {
        guard let url = URL(string: "\(baseURL)/api/generate") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are Sprout, a kind and supportive mind wellbeing assistant. 
        Give a brief, warm, and encouraging message (1-3 sentences max). 
        Be positive, supportive, and uplifting. Focus on mind wellbeing and self-care.
        Always refer to the user as "Seedling!" - they are your seedling that you're helping to grow!
        """
        
        let fullPrompt = "\(systemPrompt)\n\n\(prompt)\n\nSprout:"
        
        let body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false,
            "options": [
                "temperature": 0.8,
                "top_p": 0.9,
                "max_tokens": 100,
                "stop": ["Seedling!:", "Sprout:"]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Ollama encouragement error: \(response)")
                return nil
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseText = json["response"] as? String {
                // Clean up the response - remove any "answer:" prefix if present
                let cleaned = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.lowercased().hasPrefix("answer:") {
                    return String(cleaned.dropFirst("answer:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return cleaned
            }
            
            return nil
        } catch {
            print("❌ Ollama encouragement request failed: \(error)")
            return nil
        }
    }
    
    func checkAvailability() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    func listModels() async -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("❌ Ollama: Failed to list models - status \(statusCode)")
                return []
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { modelDict -> String? in
                    if let modelInfo = modelDict["name"] as? String {
                        // Ollama returns names like "llama3.2:latest" - extract base name
                        return modelInfo.components(separatedBy: ":").first
                    }
                    return nil
                }
                return Array(Set(modelNames)).sorted() // Remove duplicates and sort
            }
            
            return []
        } catch {
            print("❌ Ollama: Failed to list models - \(error.localizedDescription)")
            return []
        }
    }
    
    private func parseResponse(_ text: String) -> ParsedResponse? {
        // Parse format: "answer: ...\n\ntone: ...\n\nanalysis: ..."
        let lines = text.components(separatedBy: "\n")
        var answer: String?
        var tone: String?
        var analysis: String?
        
        var currentSection: String?
        var currentContent: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                if let section = currentSection, !currentContent.isEmpty {
                    if section == "answer" {
                        answer = currentContent.joined(separator: " ")
                    } else if section == "tone" {
                        tone = currentContent.joined(separator: " ").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if section == "analysis" {
                        analysis = currentContent.joined(separator: " ")
                    }
                    currentContent = []
                }
                continue
            }
            
            if trimmed.lowercased().hasPrefix("answer:") {
                if let section = currentSection, !currentContent.isEmpty {
                    if section == "answer" {
                        answer = currentContent.joined(separator: " ")
                    } else if section == "tone" {
                        tone = currentContent.joined(separator: " ").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if section == "analysis" {
                        analysis = currentContent.joined(separator: " ")
                    }
                }
                currentSection = "answer"
                let content = String(trimmed.dropFirst("answer:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    currentContent = [content]
                } else {
                    currentContent = []
                }
            } else if trimmed.lowercased().hasPrefix("tone:") {
                if let section = currentSection, !currentContent.isEmpty {
                    if section == "answer" {
                        answer = currentContent.joined(separator: " ")
                    } else if section == "tone" {
                        tone = currentContent.joined(separator: " ").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if section == "analysis" {
                        analysis = currentContent.joined(separator: " ")
                    }
                }
                currentSection = "tone"
                let content = String(trimmed.dropFirst("tone:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    tone = content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                }
                currentContent = []
            } else if trimmed.lowercased().hasPrefix("analysis:") {
                if let section = currentSection, !currentContent.isEmpty {
                    if section == "answer" {
                        answer = currentContent.joined(separator: " ")
                    } else if section == "tone" {
                        tone = currentContent.joined(separator: " ").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if section == "analysis" {
                        analysis = currentContent.joined(separator: " ")
                    }
                }
                currentSection = "analysis"
                let content = String(trimmed.dropFirst("analysis:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    currentContent = [content]
                } else {
                    currentContent = []
                }
            } else if let section = currentSection {
                currentContent.append(trimmed)
            }
        }
        
        // Handle remaining content
        if let section = currentSection, !currentContent.isEmpty {
            if section == "answer" {
                answer = currentContent.joined(separator: " ")
            } else if section == "tone" {
                tone = currentContent.joined(separator: " ").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            } else if section == "analysis" {
                analysis = currentContent.joined(separator: " ")
            }
        }
        
        // Store analysis for later retrieval
        if let analysis = analysis {
            NotificationCenter.default.post(
                name: NSNotification.Name("ConversationAnalysis"),
                object: ["answer": answer ?? "", "analysis": analysis, "tone": tone ?? "default"]
            )
        }
        
        // Return parsed response
        guard let answer = answer, !answer.isEmpty else {
            return nil
        }
        
        return ParsedResponse(answer: answer.trimmingCharacters(in: .whitespacesAndNewlines), tone: tone, analysis: analysis)
    }
}

