"""OpenVoice integration for voice cloning and synthesis."""
import os
import torch
import numpy as np
import soundfile as sf
from pathlib import Path
from typing import Optional, Tuple, List
import sys

# Add OpenVoice to path if needed
sys.path.append(str(Path(__file__).parent.parent.parent))

from src.utils.config import config
from src.utils.logger import logger

try:
    from openvoice import se_extractor
    from openvoice.api import BaseSpeakerTTS, ToneColorConverter
    OPENVOICE_AVAILABLE = True
except ImportError:
    OPENVOICE_AVAILABLE = False
    logger.warning("OpenVoice not available. Install from https://github.com/myshell-ai/OpenVoice")

class OpenVoiceClient:
    """Client for OpenVoice voice cloning and synthesis."""
    
    def __init__(self):
        """Initialize OpenVoice client."""
        self.device = config.openvoice_device
        self.model_path = Path(config.openvoice_model_path)
        
        if not OPENVOICE_AVAILABLE:
            logger.warning("OpenVoice not available. Will use fallback TTS.")
            self.base_speaker_tts = None
            self.tone_color_converter = None
            return
        
        # Initialize models
        self._initialize_models()
        if self.base_speaker_tts and self.tone_color_converter:
            logger.info(f"OpenVoice client initialized on device: {self.device}")
        else:
            logger.warning("OpenVoice models not loaded. Will use fallback TTS.")
    
    def _initialize_models(self):
        """Initialize OpenVoice models."""
        try:
            # Base speaker TTS model
            ckpt_base = self.model_path / "checkpoints" / "base_speakers" / "EN"
            if not ckpt_base.exists():
                logger.warning(f"Base model not found at {ckpt_base}. Please download models.")
                self.base_speaker_tts = None
            else:
                self.base_speaker_tts = BaseSpeakerTTS(
                    f"{ckpt_base}/config.json",
                    device=self.device
                )
                self.base_speaker_tts.load_ckpt(f"{ckpt_base}/checkpoint.pth")
            
            # Tone color converter
            ckpt_converter = self.model_path / "checkpoints" / "converter"
            if not ckpt_converter.exists():
                logger.warning(f"Converter model not found at {ckpt_converter}. Please download models.")
                self.tone_color_converter = None
            else:
                self.tone_color_converter = ToneColorConverter(
                    f"{ckpt_converter}/config.json",
                    device=self.device
                )
                self.tone_color_converter.load_ckpt(f"{ckpt_converter}/checkpoint.pth")
            
            # Speaker embeddings directory
            self.src_path = self.model_path / "checkpoints" / "base_speakers" / "EN" / "speaker_embeddings"
            
        except Exception as e:
            logger.error(f"Error initializing OpenVoice models: {e}")
            self.base_speaker_tts = None
            self.tone_color_converter = None
    
    def clone_voice(
        self,
        text: str,
        reference_audio_path: str,
        language: str = "English",
        output_path: Optional[str] = None,
        speed: float = 1.0,
        emotion: str = "default"
    ) -> Optional[np.ndarray]:
        """
        Clone voice from reference audio and generate speech.
        
        Args:
            text: Text to synthesize
            reference_audio_path: Path to reference audio for voice cloning
            language: Language of the text
            output_path: Optional path to save output audio
            speed: Speech speed multiplier
            emotion: Emotion/style of speech
            
        Returns:
            Audio array or None if generation fails
        """
        if not self.base_speaker_tts or not self.tone_color_converter:
            logger.error("OpenVoice models not initialized")
            return None
        
        try:
            # Extract speaker embedding from reference
            reference_audio = reference_audio_path
            if not os.path.exists(reference_audio):
                logger.error(f"Reference audio not found: {reference_audio}")
                return None
            
            speaker_embedding = se_extractor.get_se(
                reference_audio,
                self.tone_color_converter,
                vad_model=None,
                target_sample_rate=24000
            )
            
            # Generate base speech
            src_path = self.src_path / f"{language}.pth"
            if not src_path.exists():
                logger.warning(f"Speaker embedding not found for {language}, using default")
                src_path = list(self.src_path.glob("*.pth"))[0] if list(self.src_path.glob("*.pth")) else None
                if not src_path:
                    logger.error("No speaker embeddings found")
                    return None
            
            # Synthesize speech
            encode_message = "@MyShell"
            tts_model = self.base_speaker_tts
            
            # Generate audio
            audio = tts_model.tts(
                text,
                src_path,
                speaker_embedding=speaker_embedding,
                language=language
            )
            
            # Convert to numpy array
            if isinstance(audio, torch.Tensor):
                audio = audio.cpu().numpy()
            
            # Adjust speed if needed
            if speed != 1.0:
                audio = self._adjust_speed(audio, speed)
            
            # Save if output path provided
            if output_path:
                sf.write(output_path, audio, config.sample_rate)
                logger.info(f"Audio saved to {output_path}")
            
            return audio
            
        except Exception as e:
            logger.error(f"Error in voice cloning: {e}")
            return None
    
    def synthesize(
        self,
        text: str,
        language: str = "English",
        speaker: str = "default",
        output_path: Optional[str] = None,
        speed: float = 1.0
    ) -> Optional[np.ndarray]:
        """
        Synthesize speech without voice cloning.
        
        Args:
            text: Text to synthesize
            language: Language of the text
            speaker: Speaker ID
            output_path: Optional path to save output audio
            speed: Speech speed multiplier
            
        Returns:
            Audio array or None if generation fails
        """
        if not self.base_speaker_tts:
            logger.error("OpenVoice models not initialized")
            return None
        
        try:
            src_path = self.src_path / f"{language}.pth"
            if not src_path.exists():
                src_path = list(self.src_path.glob("*.pth"))[0] if list(self.src_path.glob("*.pth")) else None
                if not src_path:
                    logger.error("No speaker embeddings found")
                    return None
            
            # Generate audio
            audio = self.base_speaker_tts.tts(
                text,
                src_path,
                language=language
            )
            
            # Convert to numpy array
            if isinstance(audio, torch.Tensor):
                audio = audio.cpu().numpy()
            
            # Adjust speed
            if speed != 1.0:
                audio = self._adjust_speed(audio, speed)
            
            # Save if output path provided
            if output_path:
                sf.write(output_path, audio, config.sample_rate)
            
            return audio
            
        except Exception as e:
            logger.error(f"Error in speech synthesis: {e}")
            return None
    
    def _adjust_speed(self, audio: np.ndarray, speed: float) -> np.ndarray:
        """Adjust audio playback speed."""
        try:
            import librosa
            return librosa.effects.time_stretch(audio, rate=speed)
        except Exception as e:
            logger.warning(f"Could not adjust speed: {e}")
            return audio
    
    def is_available(self) -> bool:
        """Check if OpenVoice is available and models are loaded."""
        return (
            OPENVOICE_AVAILABLE and
            self.base_speaker_tts is not None and
            self.tone_color_converter is not None
        )

