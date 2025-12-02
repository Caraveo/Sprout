import AVFoundation
import Accelerate

class AudioAnalyzer: ObservableObject {
    @Published var audioLevel: Float = 0.0
    @Published var audioFrequency: Float = 0.0 // Dominant frequency (0-1, normalized)
    @Published var audioIntensity: Float = 0.0 // Overall intensity
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var debugCounter = 0
    
    // Adaptive noise handling for loud environments
    private var baselineNoiseLevel: Float = 0.0
    private var noiseSamples: [Float] = []
    private let maxNoiseSamples = 100 // Track last 100 samples for baseline
    private var adaptiveThreshold: Float = 0.3 // Dynamic threshold based on environment
    
    func start() {
        // Try to setup audio engine - system will prompt for permission on macOS
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            print("❌ Failed to create audio engine")
            startFakeAudio()
            return
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            print("❌ Failed to get input node")
            startFakeAudio()
            return
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("✅ Audio format: \(recordingFormat)")
        print("   Sample rate: \(recordingFormat.sampleRate)")
        print("   Channel count: \(recordingFormat.channelCount)")
        
        // Install tap to get audio data
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            print("✅ Audio engine started successfully - listening for audio input")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            print("   Error details: \(error.localizedDescription)")
            print("   This might be due to missing microphone permission.")
            print("   Please grant microphone access in System Settings > Privacy & Security > Microphone")
            print("   Falling back to fake audio for testing...")
            // Start fake audio for testing
            startFakeAudio()
        }
    }
    
    private func startFakeAudio() {
        print("⚠️ Using fake audio - real microphone not available")
        // Create a timer that simulates audio input for testing
        var time: Float = 0
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            time += 0.016
            // Create a pulsing pattern that varies
            let baseLevel: Float = 0.3
            let variation = sin(time * 3.0) * 0.3 + cos(time * 5.0) * 0.2
            let fakeLevel = max(0.1, min(1.0, baseLevel + variation))
            let fakeFreq = (sin(time * 2.0) * 0.5 + 0.5)
            let fakeIntensity = (fakeLevel + fakeFreq) * 0.5
            
            DispatchQueue.main.async {
                self?.audioLevel = fakeLevel
                self?.audioFrequency = fakeFreq
                self?.audioIntensity = fakeIntensity
                // Debug: print every second
                if Int(time) % 1 == 0 && time.truncatingRemainder(dividingBy: 1.0) < 0.1 {
                    print("📊 Fake Audio - Level: \(fakeLevel), Freq: \(fakeFreq), Intensity: \(fakeIntensity)")
                }
            }
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        guard buffer.frameLength > 0 else { return }
        
        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        let stride = Int(buffer.stride)
        
        var channelDataValueArray: [Float] = []
        for i in 0..<frameLength {
            if i * stride < frameLength {
                channelDataValueArray.append(channelDataValue[i * stride])
            }
        }
        
        guard !channelDataValueArray.isEmpty else { return }
        
        // Calculate RMS (Root Mean Square) for audio level
        var rms: Float = 0.0
        vDSP_rmsqv(channelDataValueArray, 1, &rms, vDSP_Length(channelDataValueArray.count))
        
        // Calculate frequency characteristics (simple high-frequency detection)
        var highFreqEnergy: Float = 0.0
        var lowFreqEnergy: Float = 0.0
        let frameCount = channelDataValueArray.count
        
        // More sophisticated frequency analysis: detect high vs low frequency content
        // Use FFT-like approach by analyzing different frequency bands
        let midPoint = frameCount / 3
        let highPoint = frameCount * 2 / 3
        
        for i in 0..<min(frameCount, 512) {
            let sample = abs(channelDataValueArray[i])
            if i > highPoint {
                // High frequency band
                highFreqEnergy += sample * 1.5 // Boost high frequencies
            } else if i > midPoint {
                // Mid frequency band
                highFreqEnergy += sample * 0.7
                lowFreqEnergy += sample * 0.3
            } else {
                // Low frequency band
                lowFreqEnergy += sample * 1.2 // Boost low frequencies
            }
        }
        
        let totalFreqEnergy = highFreqEnergy + lowFreqEnergy
        let frequencyRatio = totalFreqEnergy > 0.001 ? highFreqEnergy / totalFreqEnergy : 0.4 // Default to slightly mid-range
        
        // Normalize audio level - reduced sensitivity for loud environments
        // Lower multiplier accounts for loud ambient noise
        let normalizedLevel = min(rms * 25.0, 1.0) // Reduced from 50.0 for loud environments
        let normalizedFrequency = min(frequencyRatio * 1.5, 1.0) // Normalize frequency ratio
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Adaptive noise baseline - learn the environment's noise floor
            self.noiseSamples.append(normalizedLevel)
            if self.noiseSamples.count > self.maxNoiseSamples {
                self.noiseSamples.removeFirst()
            }
            
            // Calculate baseline as median of recent samples (more robust than mean)
            let sortedSamples = self.noiseSamples.sorted()
            let medianIndex = sortedSamples.count / 2
            self.baselineNoiseLevel = sortedSamples[medianIndex]
            
            // Adaptive threshold: baseline + 20% for loud environments
            self.adaptiveThreshold = max(0.2, min(0.6, self.baselineNoiseLevel + 0.2))
            
            // Noise gate: subtract baseline noise to get actual signal
            let signalLevel = max(0.0, normalizedLevel - self.baselineNoiseLevel * 0.7)
            let gatedLevel = signalLevel / max(0.01, 1.0 - self.baselineNoiseLevel * 0.7) // Normalize after gating
            
            // Smooth transition - adjusted for loud environments
            if let currentLevel = self.audioLevel {
                // Slower smoothing in loud environments to reduce jitter
                let smoothingFactor = self.baselineNoiseLevel > 0.4 ? 0.3 : 0.2
                self.audioLevel = currentLevel * (1.0 - smoothingFactor) + gatedLevel * smoothingFactor
            } else {
                self.audioLevel = gatedLevel
            }
            
            // Much faster frequency response for rapid color transitions
            if let currentFreq = self.audioFrequency {
                self.audioFrequency = currentFreq * 0.15 + normalizedFrequency * 0.85
            } else {
                self.audioFrequency = normalizedFrequency
            }
            
            // Audio intensity (combination of level and frequency) - adjusted for loud environments
            // Use gated level instead of raw normalized level
            self.audioIntensity = (gatedLevel + normalizedFrequency) * 0.5
            
            // Debug: print occasionally with noise info
            self.debugCounter += 1
            if self.debugCounter % 100 == 0 {
                print("📊 Audio - Level: \(String(format: "%.3f", gatedLevel)), Baseline: \(String(format: "%.3f", self.baselineNoiseLevel)), Threshold: \(String(format: "%.3f", self.adaptiveThreshold)), Intensity: \(String(format: "%.3f", self.audioIntensity))")
            }
            
            // Debug: print occasionally
            self?.debugCounter += 1
            if let counter = self?.debugCounter, counter % 100 == 0 {
                print("📊 Real Audio - Level: \(String(format: "%.3f", normalizedLevel)), Freq: \(String(format: "%.3f", normalizedFrequency)), Intensity: \(String(format: "%.3f", self?.audioIntensity ?? 0))")
            }
        }
    }
    
    func stop() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
    }
    
    deinit {
        stop()
    }
}

