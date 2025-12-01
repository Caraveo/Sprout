import SwiftUI
import AppKit

@main
struct SproutApp: App {
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    @StateObject private var voiceAssistant = VoiceAssistant()
    @StateObject private var wellbeingCoach = WellbeingCoach()
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var appModeDetector = AppModeDetector()
    
    init() {
        // Play startup sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SoundManager.shared.playStart()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(audioAnalyzer)
                .environmentObject(voiceAssistant)
                .environmentObject(wellbeingCoach)
                .environmentObject(appModeDetector)
                .background(TransparentBackground())
                .frame(width: 300, height: 300)
                .background(WindowAccessor())
                .onAppear {
                    globalVoiceAssistant = voiceAssistant
                    globalAppModeDetector = appModeDetector
                    // Setup menu bar
                    menuBarManager.setupMenuBar(voiceAssistant: voiceAssistant, wellbeingCoach: wellbeingCoach)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 300)
    }
    
}

struct WindowAccessor: NSViewRepresentable {
    // Keep delegate reference to prevent deallocation
    private static var windowDelegates: [NSWindow: WindowDelegate] = [:]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                setupWindow(window)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let window = view.window {
                        setupWindow(window)
                    }
                }
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private func setupWindow(_ window: NSWindow) {
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.styleMask = [.borderless, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.masksToBounds = false
        
        // Set a custom delegate to allow movement near menu bar
        // Keep a strong reference to the delegate
        let windowDelegate = WindowDelegate()
        window.delegate = windowDelegate
        // Store delegate reference to prevent deallocation
        WindowAccessor.windowDelegates[window] = windowDelegate
        
        if let contentView = window.contentView {
            let trackingArea = NSTrackingArea(
                rect: contentView.bounds,
                options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
                owner: contentView,
                userInfo: nil
            )
            contentView.addTrackingArea(trackingArea)
        }
        
        // Position at bottom right - smaller window for just orb
        // Use full screen frame to allow movement near menu bar
        if let screen = NSScreen.main {
            let screenRect = screen.frame  // Use full frame instead of visibleFrame
            let windowSize = NSSize(width: 300, height: 300)
            let x = screenRect.maxX - windowSize.width - 50
            let y = screenRect.minY + 50  // This will be near bottom, but can be moved higher
            window.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: windowSize), display: true)
        }
        
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Custom window delegate to allow movement near menu bar
class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillConstrain(_ window: NSWindow, to proposedFrame: NSRect, uponScreen screen: NSScreen?) -> NSRect {
        // Allow window to move anywhere on screen, including near menu bar
        // Only constrain to screen bounds, not visibleFrame
        guard let screen = screen ?? NSScreen.main else {
            return proposedFrame
        }
        
        let screenFrame = screen.frame
        let windowSize = proposedFrame.size
        
        // Constrain to screen bounds but allow near menu bar
        var constrainedFrame = proposedFrame
        
        // Ensure window stays within screen bounds
        if constrainedFrame.minX < screenFrame.minX {
            constrainedFrame.origin.x = screenFrame.minX
        }
        if constrainedFrame.maxX > screenFrame.maxX {
            constrainedFrame.origin.x = screenFrame.maxX - windowSize.width
        }
        if constrainedFrame.minY < screenFrame.minY {
            constrainedFrame.origin.y = screenFrame.minY
        }
        if constrainedFrame.maxY > screenFrame.maxY {
            constrainedFrame.origin.y = screenFrame.maxY - windowSize.height
        }
        
        return constrainedFrame
    }
}

struct TransparentBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}


