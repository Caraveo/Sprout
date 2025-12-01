import Foundation

class OpenVoiceService {
    private let baseURL = "http://localhost:6000" // OpenVoice service port
    private var session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    func synthesize(text: String) async -> Data? {
        guard let url = URL(string: "\(baseURL)/synthesize") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text": text,
            "language": "en",
            "style": "cute_boy",  // Request cute boy voice style
            "pitch": 1.15,  // Higher pitch for cute boy voice
            "speed": 1.1    // Slightly faster for youthful energy
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Silently fail - will use system TTS fallback
                return nil
            }
            
            return data
        } catch {
            // Silently fail - will use system TTS fallback
            return nil
        }
    }
    
    func cloneVoice(from audioData: Data) async -> Bool {
        guard let url = URL(string: "\(baseURL)/clone") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            return true
        } catch {
            print("❌ Voice cloning failed: \(error)")
            return false
        }
    }
}

