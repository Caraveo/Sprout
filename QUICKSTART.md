# Quick Start Guide

## First Run

1. **Install dependencies:**
```bash
./scripts/setup.sh
```

2. **Start the application:**
```bash
# CLI mode
python main.py

# Or web interface
python app.py
# Then open http://localhost:5000
```

## Using Sprout

### Text Mode
- Type your messages and press Enter
- Sprout will respond with empathetic, wellbeing-focused messages
- Emojis will appear based on the conversation context

### Voice Mode
- Speak naturally into your microphone
- Sprout will recognize your speech and respond with voice
- Visual emoji feedback appears in the interface

## Example Conversations

**User:** "I'm feeling anxious today"

**Sprout:** "🌺 I can sense you're feeling anxious. Let's take some deep breaths together. Remember, it's okay to not be okay. You're still moving forward."

**User:** "I had a great day!"

**Sprout:** "✨ That's wonderful to hear! I'm so glad you're feeling positive. Celebrating these moments is important."

## Features

- **Emotion Detection**: Automatically detects emotions from your input
- **Personalized Responses**: Tailored to your emotional state
- **Wellbeing Suggestions**: Provides helpful suggestions when needed
- **Emoji Feedback**: Visual emojis that match the conversation mood
- **Voice Cloning**: Natural voice synthesis (with OpenVoice)

## Tips

- Be open and honest about how you're feeling
- Sprout is designed to support, not replace professional help
- All conversations are processed locally for privacy
- Use 'quit' or Ctrl+C to exit

## Need Help?

See [INSTALL.md](INSTALL.md) for troubleshooting or check the logs in `logs/sprout.log`.

