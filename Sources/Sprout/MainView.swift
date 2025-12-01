import SwiftUI
import MetalKit
import AppKit

struct MainView: View {
    @EnvironmentObject var audioAnalyzer: AudioAnalyzer
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    @EnvironmentObject var wellbeingCoach: WellbeingCoach
    @State private var renderer: MetalRenderer?
    @State private var showingDashboard = false
    
    var body: some View {
        ZStack {
            // Background with blur
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(spacing: 0) {
                // Header with title
                HStack {
                    Text("🌱 Sprout")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showingDashboard.toggle() }) {
                        Image(systemName: showingDashboard ? "xmark.circle.fill" : "chart.bar.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                if showingDashboard {
                    WellbeingDashboard()
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    // Main content area
                    ZStack {
                        // Metal orb view
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
                        
                        // Voice assistant status
                        VStack {
                            Spacer()
                            VoiceAssistantView()
                                .padding(.bottom, 20)
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
                    }
                }
            }
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    override var mouseDownCanMoveWindow: Bool {
        return false
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let distance = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
        let maxRadius = min(bounds.width, bounds.height) * 0.4
        
        if distance <= maxRadius {
            return super.hitTest(point)
        }
        
        return nil
    }
    
    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        SoundManager.shared.playTouch()
        onTap?()
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let startLocation = mouseDownLocation else { return }
        let currentLocation = event.locationInWindow
        let distance = sqrt(pow(currentLocation.x - startLocation.x, 2) + pow(currentLocation.y - startLocation.y, 2))
        
        if distance > dragThreshold {
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


