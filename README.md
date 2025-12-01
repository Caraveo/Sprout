# 🌱 Sprout

**A beautiful voice assistant for mind wellbeing**

Sprout is a macOS application that combines voice interaction, AI-powered conversations, and beautiful visualizations to support your emotional wellness journey. Built with SwiftUI and featuring an audio-reactive ferrofluid orb, Sprout provides a gentle, supportive companion for daily mind wellbeing.

## ✨ Features

### 🎤 Voice Interaction
- **Real-time speech recognition** - Automatically listens and transcribes your words
- **AI-powered responses** - Powered by Ollama for natural, empathetic conversations
- **Voice synthesis** - OpenVoice integration for natural-sounding speech (with system TTS fallback)
- **Smart conversation flow** - Automatically detects pauses and manages conversation context

### 🌊 Visual Experience
- **Audio-reactive orb** - Beautiful Metal-rendered ferrofluid visualization that responds to your voice
- **Emoji expressions** - Visual feedback that matches the emotional tone of conversations
- **Minimalist interface** - Clean, distraction-free design focused on the orb

### 💚 Mind Wellbeing Support
- **Mood tracking** - Track your daily emotional state
- **Breathing exercises** - Guided breathing sessions (4-7-8, Box Breathing, Deep Calm)
- **Meditation sessions** - Short mindfulness practices
- **Hourly encouragements** - Random AI-generated supportive messages throughout the day
- **Conversation history** - Full log of interactions with analysis

### 🎯 Smart Features
- **Auto-start listening** - Begins listening when the app launches
- **Pause detection** - Automatically processes speech after natural pauses
- **Tap to interact** - Click the orb to stop speaking or toggle listening
- **Menu bar integration** - Quick access to all features via menu bar icon

## 🚀 Getting Started

### Prerequisites

- **macOS 13.0 or later**
- **Xcode 15.0 or later** (for building from source)
- **Ollama** - Local LLM server (default: llama3.2 model)
- **Python 3.11** - For OpenVoice service (optional, falls back to system TTS)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/caraveo/Sprout.git
   cd Sprout
   ```

2. **Set up OpenVoice (optional but recommended):**
   ```bash
   ./setup.sh
   ```

3. **Start OpenVoice service (if using):**
   ```bash
   ./services/start_openvoice.sh
   ```

4. **Ensure Ollama is running:**
   ```bash
   # Install Ollama from https://ollama.ai
   ollama serve
   # Pull the model
   ollama pull llama3.2
   ```

5. **Build and run:**
   ```bash
   swift build -c release
   .build/arm64-apple-macosx/release/Sprout
   ```

## 📖 Usage

### First Launch
- The app automatically starts listening when launched
- Grant microphone permissions when prompted
- Speak naturally - Sprout will transcribe and respond

### Basic Interactions
- **Speak** - Just talk naturally, Sprout listens automatically
- **Tap orb** - While speaking: stops speech | While listening: stops listening | Otherwise: starts listening
- **Menu bar** - Click the leaf icon for quick access to all features

### Voice Commands
- "breathing exercise" or "breathe" - Start a guided breathing session
- "meditate" or "meditation" - Begin a mindfulness session
- Natural conversation - Ask questions, share feelings, get support

### Menu Bar Features
- **Mood selection** - Track your current emotional state
- **Quick actions** - Start/stop listening, breathing exercises, meditation
- **Progress tracking** - View daily streak and weekly activity
- **Conversation log** - Review full history with AI analysis

## 🏗️ Architecture

### Core Components
- **VoiceAssistant** - Manages speech recognition, TTS, and conversation flow
- **WellbeingCoach** - Handles mood tracking, exercises, and AI interactions
- **OllamaService** - Communicates with local LLM for AI responses
- **OpenVoiceService** - Voice cloning and synthesis (optional)
- **MetalRenderer** - Audio-reactive ferrofluid orb visualization
- **AudioAnalyzer** - Real-time audio processing for visualization

### Technology Stack
- **SwiftUI** - Modern macOS UI framework
- **Metal** - GPU-accelerated graphics rendering
- **AVFoundation** - Audio processing and speech recognition
- **Speech Framework** - Real-time speech-to-text
- **Ollama** - Local LLM inference
- **OpenVoice** - Voice cloning and TTS (MIT/MyShell)

## 🔧 Configuration

### Ollama Settings
Edit `OllamaService.swift` to change:
- Model: Default is `llama3.2`
- Base URL: Default is `http://localhost:11434`

### OpenVoice Settings
Edit `services/openvoice_service.py` to configure:
- Port: Default is `6000`
- Model paths: Update checkpoint and config paths

## 📝 Development

### Project Structure
```
Sprout/
├── Sources/Sprout/          # Main Swift source files
│   ├── SproutApp.swift       # App entry point
│   ├── MainView.swift        # Main UI
│   ├── VoiceAssistant.swift # Speech & conversation
│   ├── WellbeingCoach.swift # Wellbeing features
│   ├── MetalRenderer.swift  # Orb visualization
│   └── ...
├── services/                 # Python services
│   └── openvoice_service.py  # OpenVoice HTTP service
├── Package.swift            # Swift package definition
└── README.md                # This file
```

### Building
```bash
# Debug build
swift build

# Release build
swift build -c release

# Run
swift run
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

See [COPYRIGHT.md](COPYRIGHT.md) for license information.

## 🙏 Acknowledgments

- **Fierro** - Base ferrofluid orb visualization (https://github.com/caraveo/fierro)
- **OpenVoice** - Voice cloning technology (https://github.com/myshell-ai/OpenVoice)
- **Ollama** - Local LLM inference (https://ollama.ai)

## 💡 Tips

- **Privacy-first** - All AI processing happens locally via Ollama
- **Offline capable** - Works without internet (except for initial model downloads)
- **Customizable** - Easy to modify prompts, models, and responses
- **Lightweight** - Minimal resource usage when idle

---

**Made with 💚 for mind wellbeing**
