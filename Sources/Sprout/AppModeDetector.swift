import Foundation
import AppKit
import CoreGraphics

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
    @Published var windowBeneath: String? = nil
    @Published var frontmostApp: String? = nil
    
    private var detectionTimer: Timer?
    private var sproutWindow: NSWindow?
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
    
    func setSproutWindow(_ window: NSWindow) {
        self.sproutWindow = window
    }
    
    func startDetection() {
        // Check every 1 second for active apps and window beneath
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.detectCurrentMode()
            self?.detectWindowBeneath()
        }
        // Initial detection
        detectCurrentMode()
        detectWindowBeneath()
    }
    
    private func detectWindowBeneath() {
        // Get the frontmost application (what the user is actually using)
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            frontmostApp = nil
            windowBeneath = nil
            return
        }
        
        let appName = frontApp.localizedName ?? ""
        let bundleId = frontApp.bundleIdentifier ?? ""
        
        frontmostApp = appName
        
        // If Sprout is the frontmost app, try to find what's behind it
        if appName == "Sprout" || bundleId.contains("Sprout") {
            // Get all windows and find the one beneath Sprout
            if let sproutWindow = sproutWindow {
                let sproutFrame = sproutWindow.frame
                let centerPoint = NSPoint(
                    x: sproutFrame.midX,
                    y: sproutFrame.midY
                )
                
                // Use CoreGraphics to find window at point
                let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
                let screenHeight = NSScreen.main?.frame.height ?? 0
                let cgPoint = CGPoint(x: centerPoint.x, y: screenHeight - centerPoint.y)
                
                var bestWindowName: String? = nil
                var bestLayer = Int.max
                
                for windowInfo in windowList ?? [] {
                    // Skip Sprout windows
                    if let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                       ownerName == "Sprout" {
                        continue
                    }
                    
                    if let windowBounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                       let x = windowBounds["X"] as? CGFloat,
                       let y = windowBounds["Y"] as? CGFloat,
                       let width = windowBounds["Width"] as? CGFloat,
                       let height = windowBounds["Height"] as? CGFloat {
                        
                        let windowFrame = CGRect(x: x, y: y, width: width, height: height)
                        
                        // Check if point is in this window
                        if windowFrame.contains(cgPoint) {
                            let layer = windowInfo[kCGWindowLayer as String] as? Int ?? 0
                            let ownerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
                            
                            // Prefer windows on normal layer (0) or lower layer numbers
                            if bestWindowName == nil || (layer < bestLayer) {
                                bestWindowName = ownerName
                                bestLayer = layer
                            }
                        }
                    }
                }
                
                windowBeneath = bestWindowName ?? getSecondMostRecentApp()
            } else {
                windowBeneath = getSecondMostRecentApp()
            }
        } else {
            // Sprout is not frontmost, so the frontmost app is what's beneath
            windowBeneath = appName
        }
    }
    
    private func getWindowAt(point: NSPoint, excluding: NSWindow) -> NSWindow? {
        // Get all windows from all applications using CoreGraphics
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        
        // Convert NSPoint to CGPoint (accounting for coordinate system differences)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let cgPoint = CGPoint(x: point.x, y: screenHeight - point.y)
        
        var bestWindow: (name: String, layer: Int)? = nil
        
        for windowInfo in windowList ?? [] {
            // Skip Sprout windows
            if let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
               ownerName == "Sprout" {
                continue
            }
            
            if let windowBounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
               let x = windowBounds["X"] as? CGFloat,
               let y = windowBounds["Y"] as? CGFloat,
               let width = windowBounds["Width"] as? CGFloat,
               let height = windowBounds["Height"] as? CGFloat {
                
                let windowFrame = CGRect(x: x, y: y, width: width, height: height)
                
                // Check if point is in this window
                if windowFrame.contains(cgPoint) {
                    let layer = windowInfo[kCGWindowLayer as String] as? Int ?? 0
                    let ownerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
                    
                    // Prefer windows on normal layer (0) over others
                    if bestWindow == nil || (layer == 0 && bestWindow!.layer != 0) || (layer < bestWindow!.layer) {
                        bestWindow = (name: ownerName, layer: layer)
                    }
                }
            }
        }
        
        // Return the window name (we can't easily get NSWindow from CGWindowInfo)
        return nil // We'll use the name directly
    }
    
    private func getSecondMostRecentApp() -> String? {
        // Get running applications sorted by activation date
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .sorted { app1, app2 in
                guard let date1 = app1.launchDate, let date2 = app2.launchDate else {
                    return false
                }
                return date1 > date2
            }
        
        // Skip Sprout and get the second one
        for app in runningApps {
            let appName = app.localizedName ?? ""
            if appName != "Sprout" && !appName.isEmpty {
                return appName
            }
        }
        
        return nil
    }
    
    func stopDetection() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }
    
    private func detectCurrentMode() {
        // Use the window beneath or frontmost app for mode detection
        let appToCheck = windowBeneath ?? frontmostApp ?? ""
        let appName = appToCheck
        
        // Get bundle ID if we can find the app
        var bundleId = ""
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            if frontApp.localizedName == appName {
                bundleId = frontApp.bundleIdentifier ?? ""
            }
        }
        
        // Also check all running apps to find bundle ID
        if bundleId.isEmpty {
            for app in NSWorkspace.shared.runningApplications {
                if app.localizedName == appName {
                    bundleId = app.bundleIdentifier ?? ""
                    break
                }
            }
        }
        
        // Check for known games first (games often run full-screen but detection varies)
        var isGame = false
        for (gameName, identifiers) in knownGames {
            for identifier in identifiers {
                if appName.localizedCaseInsensitiveContains(identifier) ||
                   bundleId.localizedCaseInsensitiveContains(identifier.lowercased()) {
                    isGame = true
                    if currentMode != .gaming || detectedApp != gameName {
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
                if currentMode != .gaming || detectedApp != appName {
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
        
        // Check for working apps - expanded list
        let expandedWorkingApps = workingApps + [
            "Terminal", "iTerm2", "Alacritty", "Warp",
            "Finder", "Activity Monitor", "System Settings",
            "Mail", "Calendar", "Notes", "Reminders"
        ]
        
        if expandedWorkingApps.contains(where: { appName.localizedCaseInsensitiveContains($0) || bundleId.localizedCaseInsensitiveContains($0.lowercased()) }) {
            if currentMode != .working || detectedApp != appName {
                currentMode = .working
                detectedApp = appName
                print("🎯 Mode changed to: Working (\(appName))")
            }
            return
        }
        
        // Check for creative apps
        if creativeApps.contains(where: { appName.localizedCaseInsensitiveContains($0) || bundleId.localizedCaseInsensitiveContains($0.lowercased()) }) {
            if currentMode != .creative || detectedApp != appName {
                currentMode = .creative
                detectedApp = appName
                print("🎨 Mode changed to: Creative (\(appName))")
            }
            return
        }
        
        // Default to normal if no special mode detected
        if currentMode != .normal {
            currentMode = .normal
            detectedApp = appName.isEmpty ? nil : appName
            print("🌱 Mode changed to: Normal")
        }
    }
    
    
    func getModeContext() -> String {
        var context = ""
        
        // Add window/app context
        if let windowBeneath = windowBeneath, !windowBeneath.isEmpty {
            context += "The user is currently using \(windowBeneath). "
        } else if let frontmost = frontmostApp, !frontmost.isEmpty, frontmost != "Sprout" {
            context += "The user is currently using \(frontmost). "
        }
        
        // Add mode context
        switch currentMode {
        case .gaming:
            context += "Gaming mode is active! The user is playing \(detectedApp ?? "a game")."
        case .working:
            context += "Working mode - the user is focused on work tasks."
        case .creative:
            context += "Creative mode - the user is doing creative work."
        case .normal:
            if context.isEmpty {
                context = "Normal mode - no specific activity detected."
            }
        }
        
        return context
    }
    
    func getApplicationMention() -> String? {
        // Get the app to mention in conversation
        if let windowBeneath = windowBeneath, !windowBeneath.isEmpty, windowBeneath != "Sprout" {
            return windowBeneath
        } else if let frontmost = frontmostApp, !frontmost.isEmpty, frontmost != "Sprout" {
            return frontmost
        }
        return nil
    }
}

