"""Configuration management for Sprout voice assistant."""
import os
import yaml
from pathlib import Path
from dotenv import load_dotenv
from typing import Dict, Any

# Load environment variables
load_dotenv()

class Config:
    """Central configuration class for the application."""
    
    def __init__(self, config_path: str = None):
        """Initialize configuration from file and environment variables."""
        self.base_dir = Path(__file__).parent.parent.parent
        self.config_path = config_path or self.base_dir / "config.yaml"
        
        # Load YAML config if exists
        self.config = {}
        if self.config_path.exists():
            with open(self.config_path, 'r') as f:
                self.config = yaml.safe_load(f) or {}
        
        # OpenVoice settings
        self.openvoice_model_path = os.getenv(
            'OPENVOICE_MODEL_PATH',
            self.config.get('openvoice', {}).get('model_path', './models/openvoice')
        )
        self.openvoice_device = os.getenv(
            'OPENVOICE_DEVICE',
            self.config.get('openvoice', {}).get('device', 'cpu')
        )
        
        # Voice settings
        self.default_voice_speed = float(os.getenv(
            'DEFAULT_VOICE_SPEED',
            self.config.get('voice', {}).get('speed', 1.0)
        ))
        self.default_voice_emotion = os.getenv(
            'DEFAULT_VOICE_EMOTION',
            self.config.get('voice', {}).get('emotion', 'calm')
        )
        self.supported_languages = os.getenv(
            'SUPPORTED_LANGUAGES',
            self.config.get('voice', {}).get('languages', 'en,es,fr,zh,ja,ko')
        ).split(',')
        
        # Assistant settings
        self.assistant_name = os.getenv(
            'ASSISTANT_NAME',
            self.config.get('assistant', {}).get('name', 'Sprout')
        )
        self.conversation_mode = os.getenv(
            'CONVERSATION_MODE',
            self.config.get('assistant', {}).get('mode', 'wellbeing')
        )
        self.max_conversation_history = int(os.getenv(
            'MAX_CONVERSATION_HISTORY',
            self.config.get('assistant', {}).get('max_history', 50)
        ))
        
        # Audio settings
        self.sample_rate = int(os.getenv(
            'SAMPLE_RATE',
            self.config.get('audio', {}).get('sample_rate', 24000)
        ))
        self.audio_chunk_size = int(os.getenv(
            'AUDIO_CHUNK_SIZE',
            self.config.get('audio', {}).get('chunk_size', 1024)
        ))
        self.vad_aggressiveness = int(os.getenv(
            'VAD_AGGRESSIVENESS',
            self.config.get('audio', {}).get('vad_aggressiveness', 2)
        ))
        
        # Emoji settings
        self.emoji_enabled = os.getenv(
            'EMOJI_ENABLED',
            str(self.config.get('emoji', {}).get('enabled', True))
        ).lower() == 'true'
        self.emoji_animation_speed = float(os.getenv(
            'EMOJI_ANIMATION_SPEED',
            self.config.get('emoji', {}).get('animation_speed', 1.0)
        ))
        
        # API keys
        self.openai_api_key = os.getenv('OPENAI_API_KEY', '')
        self.google_api_key = os.getenv('GOOGLE_API_KEY', '')
        
        # Logging
        self.log_level = os.getenv(
            'LOG_LEVEL',
            self.config.get('logging', {}).get('level', 'INFO')
        )
        self.log_file = os.getenv(
            'LOG_FILE',
            self.config.get('logging', {}).get('file', 'logs/sprout.log')
        )
        
        # Ensure directories exist
        self._ensure_directories()
    
    def _ensure_directories(self):
        """Create necessary directories if they don't exist."""
        directories = [
            self.base_dir / 'models',
            self.base_dir / 'resources' / 'audio',
            self.base_dir / 'logs',
            self.base_dir / 'static',
        ]
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value by key path (e.g., 'voice.speed')."""
        keys = key.split('.')
        value = self.config
        for k in keys:
            if isinstance(value, dict):
                value = value.get(k)
                if value is None:
                    return default
            else:
                return default
        return value if value is not None else default

# Global config instance
config = Config()

