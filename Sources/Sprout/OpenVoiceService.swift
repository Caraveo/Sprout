import Foundation

class OpenVoiceService {
    private let baseURL: String
    private var session: URLSession
    
    init() {
        // Use port 6000 for OpenVoice service
        self.baseURL = "http://localhost:6000"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    func checkServiceAvailable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        
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
    
    func synthesize(text: String) async -> Data? {
        guard let url = URL(string: "\(baseURL)/synthesize") else {
            print("⚠️ OpenVoice: Invalid URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text": text,
            "language": "en",
            "style": "default"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            print("🎤 OpenVoice: Requesting synthesis for: \(text.prefix(50))...")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️ OpenVoice: Invalid response")
                return nil
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ OpenVoice: Synthesis successful (\(data.count) bytes)")
                return data
            } else {
                print("⚠️ OpenVoice: Service returned status \(httpResponse.statusCode)")
                return nil
            }
        } catch {
            print("❌ OpenVoice: Request failed - \(error.localizedDescription)")
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

