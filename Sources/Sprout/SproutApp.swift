import SwiftUI
import AppKit

@main
struct SproutApp: App {
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    @StateObject private var voiceAssistant = VoiceAssistant()
    @StateObject private var wellbeingCoach = WellbeingCoach()
    @StateObject private var menuBarManager = MenuBarManager()
    
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
                .background(TransparentBackground())
                .frame(width: 400, height: 500)
                .background(WindowAccessor())
                .onAppear {
                    globalVoiceAssistant = voiceAssistant
                    // Setup menu bar
                    menuBarManager.setupMenuBar(voiceAssistant: voiceAssistant, wellbeingCoach: wellbeingCoach)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 500)
    }
    
}

struct WindowAccessor: NSViewRepresentable {
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
        
        if let contentView = window.contentView {
            let trackingArea = NSTrackingArea(
                rect: contentView.bounds,
                options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
                owner: contentView,
                userInfo: nil
            )
            contentView.addTrackingArea(trackingArea)
        }
        
        // Position at bottom right
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowSize = NSSize(width: 400, height: 500)
            let x = screenRect.maxX - windowSize.width - 50
            let y = screenRect.minY + 50
            window.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: windowSize), display: true)
        }
        
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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


