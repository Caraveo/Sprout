import SwiftUI
import MetalKit
import AppKit

struct MainView: View {
    @EnvironmentObject var audioAnalyzer: AudioAnalyzer
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    @EnvironmentObject var wellbeingCoach: WellbeingCoach
    @State private var renderer: MetalRenderer?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Metal orb view - full screen, no background
            MetalView(renderer: $renderer)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    renderer = MetalRenderer()
                    audioAnalyzer.start()
                    
                    // Automatically start listening when app appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        voiceAssistant.startListening()
                    }
                }
                .onChange(of: audioAnalyzer.audioLevel) { newLevel in
                    renderer?.updateAudioLevel(newLevel)
                }
                .onChange(of: audioAnalyzer.audioFrequency) { newFreq in
                    renderer?.updateAudioFrequency(newFreq)
                }
                .onChange(of: audioAnalyzer.audioIntensity) { newIntensity in
                    renderer?.updateAudioIntensity(newIntensity)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AudioIntensityChanged"),
                        object: newIntensity
                    )
                }
            
            // Emoji overlay in center
            EmojiView()
                .allowsHitTesting(false)
            
            // Voice assistant status - minimal, shows when active
            VStack {
                Spacer()
                VoiceAssistantView()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
            }
            
            // Invisible draggable overlay with touch reaction
            DraggableArea(onTap: {
                renderer?.triggerTouchReaction()
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowEmoji"),
                    object: nil
                )
                voiceAssistant.handleTap()
            })
            .focusable()
            .focused($isFocused)
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Make view focusable for keyboard events
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApplication.shared.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CancelTranscription"))) { _ in
            voiceAssistant.cancelTranscription()
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct DraggableArea: NSViewRepresentable {
    var onTap: (() -> Void)?
    
    func makeNSView(context: Context) -> NSView {
        let view = DraggableNSView()
        view.onTap = onTap
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let draggableView = nsView as? DraggableNSView {
            draggableView.onTap = onTap
        }
    }
}

class DraggableNSView: NSView {
    var onTap: (() -> Void)?
    private var mouseDownLocation: NSPoint?
    private let dragThreshold: CGFloat = 3.0
    
    override var acceptsFirstResponder: Bool {
        return true  // Allow view to receive keyboard events
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return true  // Allow window to be moved by dragging
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle Esc key to cancel transcription
        if event.keyCode == 53 { // Esc key
            // Post notification to cancel transcription
            NotificationCenter.default.post(
                name: NSNotification.Name("CancelTranscription"),
                object: nil
            )
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Allow dragging from anywhere, but only tap the orb area
        return super.hitTest(point)
    }
    
    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        
        // Check if click is on the orb (center area)
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let clickPoint = event.locationInWindow
        let distance = sqrt(pow(clickPoint.x - center.x, 2) + pow(clickPoint.y - center.y, 2))
        let maxRadius = min(bounds.width, bounds.height) * 0.4
        
        if distance <= maxRadius {
            SoundManager.shared.playTouch()
            onTap?()
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let startLocation = mouseDownLocation else { return }
        let currentLocation = event.locationInWindow
        let distance = sqrt(pow(currentLocation.x - startLocation.x, 2) + pow(currentLocation.y - startLocation.y, 2))
        
        if distance > dragThreshold {
            // Allow window to be dragged anywhere
            window?.performDrag(with: event)
            mouseDownLocation = nil
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        mouseDownLocation = nil
    }
}

struct MetalView: NSViewRepresentable {
    @Binding var renderer: MetalRenderer?
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = ClickThroughMTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.layer?.isOpaque = false
        mtkView.autoresizingMask = [.width, .height]
        mtkView.layer?.masksToBounds = false
        
        if let renderer = renderer {
            renderer.setup(view: mtkView)
        }
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        if let renderer = renderer {
            renderer.setup(view: nsView)
        }
        nsView.layer?.masksToBounds = false
    }
}

class ClickThroughMTKView: MTKView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let distance = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
        let maxRadius = min(bounds.width, bounds.height) * 0.4
        
        if distance <= maxRadius {
            return super.hitTest(point)
        }
        
        return nil
    }
}


