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
        You are Sprout, a kind and supportive mind wellbeing assistant. Your role is to:
        - Be warm, positive, and encouraging
        - Keep responses SHORT (1-2 sentences max)
        - Focus on mind wellbeing and emotional support
        - Use gentle, understanding language
        - Offer practical, simple suggestions when helpful
        - Never be clinical or medical - be a friendly companion
        
        Always respond with empathy and kindness. Be brief and uplifting.
        """
        
        let fullPrompt = context.isEmpty 
            ? "\(systemPrompt)\n\nUser: \(userMessage)\nSprout:"
            : "\(systemPrompt)\n\nContext: \(context)\n\nUser: \(userMessage)\nSprout:"
        
        let body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "top_p": 0.9,
                "max_tokens": 100, // Keep responses short
                "stop": ["\n\n", "User:", "Sprout:"]
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
                // Clean up the response - remove any extra formatting
                let cleaned = responseText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "  ", with: " ")
                
                // Ensure it's not too long (max 200 characters)
                if cleaned.count > 200 {
                    let truncated = String(cleaned.prefix(197)) + "..."
                    return truncated
                }
                
                return cleaned.isEmpty ? nil : cleaned
            }
            
            return nil
        } catch {
            print("❌ Ollama request failed: \(error)")
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
}

