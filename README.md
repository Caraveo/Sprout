# 🌱 Sprout - Mind Wellbeing Voice Assistant

A comprehensive SwiftUI voice assistant application that combines voice interaction, emoji reactions, and mind wellbeing support. Built with Fierro's audio-reactive visualizations and OpenVoice for natural speech synthesis.

## Features

- **Voice Interaction**: Real-time speech recognition and natural voice responses
- **Audio-Reactive Visualizations**: Beautiful ferrofluid orb that responds to your voice
- **Emoji Reactions**: Dynamic emoji responses based on audio and conversation context
- **Mind Wellbeing Support**: 
  - Guided breathing exercises
  - Meditation sessions
  - Mood tracking
  - Daily progress tracking
- **OpenVoice Integration**: Natural voice synthesis with voice cloning capabilities

## Requirements

- macOS 13.0 or later
- Metal-capable GPU
- Microphone access
- Python 3.9+ (for OpenVoice service)

## Setup

### 1. Install Swift Dependencies

```bash
swift build
```

### 2. Setup OpenVoice Service

```bash
# Install Python dependencies
cd services
pip install -r requirements.txt

# Clone OpenVoice repository
cd ..
git clone https://github.com/myshell-ai/OpenVoice.git

# Download checkpoints (see OpenVoice README)
# Place checkpoints in checkpoints/ directory

# Start the service
python services/openvoice_service.py
```

The OpenVoice service runs on port 6000 by default.

### 3. Build and Run

```bash
# Debug build
swift build

# Release build (recommended)
swift build -c release

# Run the app
swift run -c release
```

## Usage

1. **Launch Sprout**: The app will appear at the bottom right of your screen
2. **Grant Permissions**: Allow microphone access when prompted
3. **Interact**:
   - **Tap the orb** to start/stop voice listening
   - **Speak naturally** - the assistant will respond with voice and emoji
   - **Open dashboard** - Click the chart icon to see your wellbeing progress
   - **Try exercises** - Ask for "breathing exercise" or "meditation"

## Voice Commands

- "Hello" / "Hi" - Start a conversation
- "I feel [mood]" - Share your current mood
- "Breathing exercise" - Start a guided breathing session
- "Meditation" - Begin a mindfulness session
- "Thank you" - Express gratitude

## Architecture

### SwiftUI Components

- `SproutApp.swift` - Main application entry point
- `MainView.swift` - Primary UI with orb visualization
- `VoiceAssistant.swift` - Speech recognition and synthesis
- `WellbeingCoach.swift` - Mind wellbeing features and coaching
- `EmojiView.swift` - Dynamic emoji reactions
- `MetalRenderer.swift` - Audio-reactive ferrofluid visualization
- `AudioAnalyzer.swift` - Real-time audio analysis

### Python Service

- `services/openvoice_service.py` - HTTP API for OpenVoice integration

## Customization

### Adjust Audio Sensitivity

Edit `AudioAnalyzer.swift`:
```swift
let normalizedLevel = min(rms * 50.0, 1.0) // Adjust multiplier
```

### Modify Orb Appearance

Edit `MetalRenderer.swift` shader parameters or `FerrofluidShader.metal`

### Add Wellbeing Exercises

Extend `WellbeingCoach.swift` with new exercises in the `breathingExercises` array

## Troubleshooting

### Audio Not Working

1. Check microphone permission: System Settings > Privacy & Security > Microphone
2. Verify audio engine started (check console output)
3. App will fall back to simulated audio if microphone unavailable

### OpenVoice Service Not Responding

1. Ensure service is running: `python services/openvoice_service.py`
2. Check port 6000 is available
3. Verify OpenVoice checkpoints are installed
4. App will fall back to system TTS if service unavailable

### Build Issues

- Ensure macOS 13.0+ and Metal-capable GPU
- Check Swift Package Manager can access all resources
- Verify Metal shader compilation

## License

This project integrates:
- **Fierro** - Copyright © 2024 Jonathan Caraveo (non-commercial use)
- **OpenVoice** - MIT License (free for commercial use)

## Acknowledgments

- [Fierro](https://github.com/caraveo/fierro) - Audio-reactive ferrofluid visualization
- [OpenVoice](https://github.com/myshell-ai/OpenVoice) - Voice cloning and synthesis by MIT and MyShell

