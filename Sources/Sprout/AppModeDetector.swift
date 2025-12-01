import Foundation
import AppKit

enum AppMode: String {
    case normal = "normal"
    case gaming = "gaming"
    case working = "working"
    case creative = "creative"
    
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .gaming: return "Gaming"
        case .working: return "Working"
        case .creative: return "Creative"
        }
    }
}

class AppModeDetector: ObservableObject {
    @Published var currentMode: AppMode = .normal
    @Published var detectedApp: String? = nil
    
    private var detectionTimer: Timer?
    private let knownGames = [
        "World of Warcraft": ["World of Warcraft", "Wow", "WoW"],
        "Diablo": ["Diablo"],
        "Overwatch": ["Overwatch"],
        "League of Legends": ["League of Legends", "LeagueClient"],
        "Valorant": ["VALORANT", "RiotClientServices"],
        "Counter-Strike": ["cs2", "csgo"],
        "Minecraft": ["Minecraft"],
        "Elden Ring": ["eldenring"],
        "Baldur's Gate": ["Baldur's Gate 3", "bg3"],
        "Cyberpunk": ["Cyberpunk2077"]
    ]
    
    private let workingApps = [
        "Xcode", "Visual Studio Code", "Sublime Text", "IntelliJ IDEA",
        "Slack", "Microsoft Teams", "Zoom", "Google Chrome", "Safari",
        "Microsoft Word", "Pages", "Keynote", "Numbers"
    ]
    
    private let creativeApps = [
        "Final Cut Pro", "Premiere Pro", "After Effects", "Photoshop",
        "Illustrator", "Figma", "Sketch", "Blender", "Cinema 4D"
    ]
    
    init() {
        startDetection()
    }
    
    func startDetection() {
        // Check every 2 seconds for active full-screen apps
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.detectCurrentMode()
        }
        // Initial detection
        detectCurrentMode()
    }
    
    func stopDetection() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }
    
    private func detectCurrentMode() {
        // Get the frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return
        }
        
        let appName = frontApp.localizedName ?? ""
        let bundleId = frontApp.bundleIdentifier ?? ""
        
        // Check for known games first (games often run full-screen but detection varies)
        var isGame = false
        for (gameName, identifiers) in knownGames {
            for identifier in identifiers {
                if appName.localizedCaseInsensitiveContains(identifier) ||
                   bundleId.localizedCaseInsensitiveContains(identifier.lowercased()) {
                    isGame = true
                    if currentMode != .gaming {
                        currentMode = .gaming
                        detectedApp = gameName
                        print("🎮 Mode changed to: Gaming (\(gameName))")
                        
                        // Notify that gaming mode was detected
                        NotificationCenter.default.post(
                            name: NSNotification.Name("GamingModeDetected"),
                            object: ["game": gameName]
                        )
                    }
                    return
                }
            }
        }
        
        // Check if app is in full-screen mode (for games that don't match known list)
        let isFullScreen = NSApplication.shared.keyWindow?.styleMask.contains(.fullScreen) ?? false
        
        if isFullScreen && !isGame {
            // Might be a game we don't know about - check if it looks like a game
            // (Many games have specific bundle ID patterns or window behaviors)
            if bundleId.contains("com.blizzard") || 
               bundleId.contains("com.riotgames") ||
               bundleId.contains("com.valvesoftware") ||
               bundleId.contains("com.epicgames") ||
               bundleId.contains("com.ea.") ||
               bundleId.contains("com.activision") {
                if currentMode != .gaming {
                    currentMode = .gaming
                    detectedApp = appName
                    print("🎮 Mode changed to: Gaming (\(appName))")
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("GamingModeDetected"),
                        object: ["game": appName]
                    )
                }
                return
            }
        }
        
        // Check for working/creative apps
        if workingApps.contains(where: { appName.contains($0) || bundleId.localizedCaseInsensitiveContains($0.lowercased()) }) {
            if currentMode != .working {
                currentMode = .working
                detectedApp = appName
                print("🎯 Mode changed to: Working (\(appName))")
            }
            return
        }
        
        if creativeApps.contains(where: { appName.contains($0) || bundleId.localizedCaseInsensitiveContains($0.lowercased()) }) {
            if currentMode != .creative {
                currentMode = .creative
                detectedApp = appName
                print("🎨 Mode changed to: Creative (\(appName))")
            }
            return
        }
        
        // Default to normal if no special mode detected
        if currentMode != .normal {
            currentMode = .normal
            detectedApp = nil
            print("🌱 Mode changed to: Normal")
        }
    }
    
    
    func getModeContext() -> String {
        switch currentMode {
        case .gaming:
            return "The user is currently playing \(detectedApp ?? "a game"). Gaming mode is active!"
        case .working:
            return "The user is currently working in \(detectedApp ?? "an application")."
        case .creative:
            return "The user is currently doing creative work in \(detectedApp ?? "a creative application")."
        case .normal:
            return "Normal mode - no specific activity detected."
        }
    }
}

