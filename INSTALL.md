# Installation Guide

## Prerequisites

- Python 3.8 or higher
- macOS (primary platform)
- Microphone (for voice input)
- Internet connection (for initial setup)

## Quick Setup

### Option 1: Automated Setup (Recommended)

```bash
# Run the setup script
./scripts/setup.sh
```

### Option 2: Manual Setup

1. **Create virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate
```

2. **Install dependencies:**
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

3. **Set up OpenVoice (Optional):**

OpenVoice provides high-quality voice cloning. The application will work without it using fallback TTS, but for best results:

```bash
# Clone OpenVoice repository
git clone https://github.com/myshell-ai/OpenVoice.git
cd OpenVoice

# Follow OpenVoice installation instructions
# Then copy models to Sprout/models/openvoice/
```

Alternatively, you can use the fallback TTS system which uses macOS's built-in `say` command.

4. **Configure environment (Optional):**
```bash
cp .env.example .env
# Edit .env with your preferences
```

## Running the Application

### Command Line Interface

```bash
python main.py
```

Choose between text or voice mode when prompted.

### Web Interface

```bash
python app.py
```

Then open your browser to `http://localhost:5000`

## Optional: Voice Input Support

For full voice input functionality, install `pyaudio`:

```bash
# Install system dependency first
brew install portaudio

# Then install pyaudio
pip install pyaudio
```

**Note:** The application works in text-only mode without pyaudio. Voice output (TTS) works using macOS's built-in `say` command.

## Troubleshooting

### Audio Issues

- **No microphone access:** Grant microphone permissions in System Preferences
- **Audio playback issues:** Check system audio settings
- **pyaudio not found:** Install portaudio via Homebrew first: `brew install portaudio`

### OpenVoice Issues

- If OpenVoice models are not available, the app will automatically use fallback TTS
- Check that model paths are correct in `config.yaml` or `.env`
- OpenVoice is optional - the app works with macOS TTS

### Dependencies

- If you encounter import errors, ensure all dependencies are installed:
```bash
pip install -r requirements.txt
```

- For voice input, install optional dependencies:
```bash
brew install portaudio
pip install pyaudio
```

## Notes

- The application works without OpenVoice using macOS's built-in TTS
- For production use, consider setting up OpenVoice for better voice quality
- All conversations are processed locally - no data is sent to external services (unless you configure API keys)

