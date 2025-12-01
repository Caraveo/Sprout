# Quick Start Guide

## Prerequisites

- macOS 13.0 or later
- Xcode Command Line Tools: `xcode-select --install`
- Python 3.9+ with pip

## Installation

### Option 1: Automated Setup (Recommended)

```bash
./setup.sh
```

This will:
- Create Python virtual environment
- Install dependencies
- Clone OpenVoice repository
- Build the Swift application

### Option 2: Manual Setup

1. **Install Python dependencies:**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r services/requirements.txt
```

2. **Clone OpenVoice:**
```bash
git clone https://github.com/myshell-ai/OpenVoice.git
```

3. **Download OpenVoice checkpoints:**
   - Follow instructions at https://github.com/myshell-ai/OpenVoice
   - Place checkpoints in `checkpoints/` directory

4. **Build Swift app:**
```bash
swift build -c release
```

## Running Sprout

### Step 1: Start OpenVoice Service

In one terminal:
```bash
source venv/bin/activate
python services/openvoice_service.py
```

You should see:
```
🌱 Starting Sprout OpenVoice Service on port 6000...
```

### Step 2: Run Sprout

In another terminal:
```bash
swift run -c release
```

The app will:
- Appear at the bottom right of your screen
- Request microphone permission (grant it!)
- Play a startup sound
- Show the audio-reactive orb

## First Use

1. **Tap the orb** to start voice listening (red indicator appears)
2. **Say "Hello"** - the assistant will respond
3. **Try commands:**
   - "I feel good" - share your mood
   - "Breathing exercise" - start guided breathing
   - "Meditation" - begin mindfulness session
4. **Open dashboard** - Click the chart icon (top right) to see progress

## Troubleshooting

### "Speech recognition not authorized"
- Go to System Settings > Privacy & Security > Microphone
- Enable microphone access for Terminal (or your terminal app)

### "OpenVoice service error"
- Make sure the service is running on port 6000
- Check `python services/openvoice_service.py` is running
- App will fall back to system TTS if service unavailable

### "Metal is not supported"
- Ensure you have a Metal-capable GPU
- Check macOS version is 13.0+

### Build errors
- Run `swift package clean`
- Try `swift build -c release` again
- Check all files are in `Sources/Sprout/`

## Next Steps

- Customize breathing exercises in `WellbeingCoach.swift`
- Adjust audio sensitivity in `AudioAnalyzer.swift`
- Modify orb appearance in `MetalRenderer.swift`
- Add your own voice reference for cloning

## Support

For issues with:
- **OpenVoice**: See https://github.com/myshell-ai/OpenVoice
- **Fierro**: See https://github.com/caraveo/fierro
- **Sprout**: Check the main README.md

