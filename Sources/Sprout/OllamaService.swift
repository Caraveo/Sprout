import Foundation

class OllamaService {
    private let baseURL: String
    private let model: String
    private var session: URLSession
    
    init(baseURL: String = "http://localhost:11434", model: String = "llama3.2") {
        self.baseURL = baseURL
        self.model = model
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    func generateResponse(for userMessage: String, context: String = "") async -> String? {
        guard let url = URL(string: "\(baseURL)/api/generate") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a positive, helpful, and concise system prompt
        let systemPrompt = """
        You are Seedling!, a kind and supportive mind wellbeing assistant. Your role is to:
        - Be warm, positive, and encouraging
        - Keep responses SHORT (randomly 1, 2, 3, or 4 sentences - choose randomly each time)
        - Focus on mind wellbeing and emotional support
        - Use gentle, understanding language
        - Offer practical, simple suggestions when helpful
        - Never be clinical or medical - be a friendly companion
        - Remember previous conversation context and reference it naturally when relevant
        
        CRITICAL: You MUST respond in this exact format:
        answer: [your response here - 1 to 4 sentences randomly chosen]
        
        analysis: [brief analysis of the conversation, user's emotional state, and what they might need - 1-2 sentences]
        
        Always respond with empathy and kindness. Be brief and uplifting.
        """
        
        let fullPrompt: String
        if context.isEmpty {
            fullPrompt = "\(systemPrompt)\n\nUser: \(userMessage)\nSeedling!:"
        } else {
            fullPrompt = "\(systemPrompt)\n\n\(context)\n\nUser: \(userMessage)\nSeedling!:"
        }
        
        let body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "top_p": 0.9,
                "max_tokens": 200, // Increased for answer + analysis
                "stop": ["User:", "Seedling!:"]
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
                // Parse the response format: "answer: ...\n\nanalysis: ..."
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
        You are Seedling!, a kind and supportive mind wellbeing assistant. 
        Give a brief, warm, and encouraging message (1-3 sentences max). 
        Be positive, supportive, and uplifting. Focus on mind wellbeing and self-care.
        """
        
        let fullPrompt = "\(systemPrompt)\n\n\(prompt)\n\nSeedling!:"
        
        let body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false,
            "options": [
                "temperature": 0.8,
                "top_p": 0.9,
                "max_tokens": 100,
                "stop": ["User:", "Seedling!:"]
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
    
    private func parseResponse(_ text: String) -> String? {
        // Parse format: "answer: ...\n\nanalysis: ..."
        let lines = text.components(separatedBy: "\n")
        var answer: String?
        var analysis: String?
        
        var currentSection: String?
        var currentContent: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                if let section = currentSection, !currentContent.isEmpty {
                    if section == "answer" {
                        answer = currentContent.joined(separator: " ")
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
            } else if trimmed.lowercased().hasPrefix("analysis:") {
                if let section = currentSection, !currentContent.isEmpty {
                    if section == "answer" {
                        answer = currentContent.joined(separator: " ")
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
            } else if section == "analysis" {
                analysis = currentContent.joined(separator: " ")
            }
        }
        
        // Store analysis for later retrieval
        if let analysis = analysis {
            NotificationCenter.default.post(
                name: NSNotification.Name("ConversationAnalysis"),
                object: ["answer": answer ?? "", "analysis": analysis]
            )
        }
        
        // Return just the answer for speaking
        return answer?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

