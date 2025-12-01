"""Text-to-speech engine with fallback options."""
import os
import numpy as np
import soundfile as sf
from pathlib import Path
from typing import Optional
import tempfile
import subprocess

from src.utils.config import config
from src.utils.logger import logger
from src.voice.openvoice_client import OpenVoiceClient

class TTSEngine:
    """Text-to-speech engine with multiple backends."""
    
    def __init__(self):
        """Initialize TTS engine."""
        self.openvoice_client = None
        self.fallback_enabled = True
        
        # Try to initialize OpenVoice
        try:
            self.openvoice_client = OpenVoiceClient()
            if self.openvoice_client.is_available():
                logger.info("OpenVoice TTS engine initialized")
            else:
                logger.warning("OpenVoice not available, using fallback")
                self.openvoice_client = None
        except Exception as e:
            logger.warning(f"Could not initialize OpenVoice: {e}. Using fallback TTS.")
            self.openvoice_client = None
    
    def speak(
        self,
        text: str,
        language: str = "English",
        speed: Optional[float] = None,
        emotion: str = "calm",
        reference_audio: Optional[str] = None,
        output_path: Optional[str] = None
    ) -> Optional[np.ndarray]:
        """
        Convert text to speech.
        
        Args:
            text: Text to speak
            language: Language code
            speed: Speech speed (1.0 = normal)
            emotion: Emotion/style
            reference_audio: Optional reference audio for voice cloning
            output_path: Optional path to save audio
            
        Returns:
            Audio array or None
        """
        speed = speed or config.default_voice_speed
        
        # Try OpenVoice first
        if self.openvoice_client and self.openvoice_client.is_available():
            try:
                if reference_audio:
                    audio = self.openvoice_client.clone_voice(
                        text=text,
                        reference_audio_path=reference_audio,
                        language=language,
                        output_path=output_path,
                        speed=speed,
                        emotion=emotion
                    )
                else:
                    audio = self.openvoice_client.synthesize(
                        text=text,
                        language=language,
                        output_path=output_path,
                        speed=speed
                    )
                
                if audio is not None:
                    return audio
            except Exception as e:
                logger.warning(f"OpenVoice synthesis failed: {e}")
        
        # Fallback to system TTS
        if self.fallback_enabled:
            return self._fallback_speak(text, output_path)
        
        return None
    
    def _fallback_speak(self, text: str, output_path: Optional[str] = None) -> Optional[np.ndarray]:
        """Fallback TTS using system commands."""
        try:
            # Use macOS say command
            if output_path is None:
                output_path = tempfile.mktemp(suffix='.wav')
            
            # Use macOS say command
            subprocess.run([
                'say',
                '-v', 'Samantha',  # Calm, friendly voice
                '-o', output_path,
                text
            ], check=True, capture_output=True)
            
            # Load audio file
            if os.path.exists(output_path):
                audio, sr = sf.read(output_path)
                return audio
            
        except Exception as e:
            logger.error(f"Fallback TTS failed: {e}")
        
        return None
    
    def play_audio(self, audio: np.ndarray, sample_rate: int = None):
        """
        Play audio array.
        
        Args:
            audio: Audio array
            sample_rate: Sample rate (defaults to config)
        """
        try:
            sample_rate = sample_rate or config.sample_rate
            
            # Save to temp file and play
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
                sf.write(tmp.name, audio, sample_rate)
                tmp_path = tmp.name
            
            # Play using system command
            subprocess.Popen(['afplay', tmp_path], 
                           stdout=subprocess.DEVNULL, 
                           stderr=subprocess.DEVNULL)
            
            # Clean up after a delay
            import threading
            def cleanup():
                import time
                time.sleep(len(audio) / sample_rate + 1)
                try:
                    os.unlink(tmp_path)
                except:
                    pass
            
            threading.Thread(target=cleanup, daemon=True).start()
            
        except Exception as e:
            logger.error(f"Error playing audio: {e}")

