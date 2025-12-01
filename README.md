# Sprout - Mind Wellbeing Voice Assistant

A comprehensive voice assistant that uses voice cloning (OpenVoice) and emoji-based visual feedback to support mind wellbeing.

## Features

- **Voice Cloning**: Uses OpenVoice for natural, empathetic voice synthesis
- **Emoji Feedback**: Dynamic emoji reactions that respond to conversation context and emotions
- **Mind Wellbeing Focus**: Conversations designed to support emotional wellness (not medical advice)
- **Real-time Interaction**: Live voice recognition and response generation
- **Multi-language Support**: Supports multiple languages through OpenVoice
- **Emotion Detection**: Automatically detects and responds to emotional states
- **Visual Feedback**: Emoji-based visual system that adapts to conversation mood

## Quick Start

```bash
# Run automated setup
./scripts/setup.sh

# Or manually:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

For detailed installation instructions, see [INSTALL.md](INSTALL.md).

**Note:** OpenVoice is optional. The app works with macOS's built-in TTS if OpenVoice models are not available.

## Usage

### Command Line Interface
```bash
python main.py
```

### Web Interface
```bash
python app.py
```

Then navigate to `http://localhost:5000` in your browser.

## Project Structure

```
Sprout/
├── app.py                 # Flask web application
├── main.py               # CLI interface
├── src/
│   ├── voice/
│   │   ├── openvoice_client.py    # OpenVoice integration
│   │   ├── speech_recognition.py  # Speech input handling
│   │   └── tts_engine.py          # Text-to-speech engine
│   ├── assistant/
│   │   ├── conversation_engine.py  # Main conversation logic
│   │   ├── wellbeing_coach.py     # Mind wellbeing responses
│   │   └── emotion_detector.py     # Emotion analysis
│   ├── visual/
│   │   ├── emoji_engine.py        # Emoji selection and display
│   │   └── visual_feedback.py     # Visual feedback system
│   └── utils/
│       ├── config.py              # Configuration management
│       └── logger.py              # Logging utilities
├── models/               # Model files (downloaded)
├── resources/            # Audio samples and resources
├── scripts/              # Setup and utility scripts
└── static/               # Web static files
```

## Configuration

Edit `config.yaml` or set environment variables to customize:
- Voice settings
- Emoji preferences
- Conversation parameters
- API keys (if using external services)

## License

MIT License

## Acknowledgments

- OpenVoice by MIT and MyShell
- Built with care for mind wellbeing

