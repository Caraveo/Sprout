"""Speech recognition for voice input."""
import speech_recognition as sr
import pyaudio
import webrtcvad
import numpy as np
from typing import Optional, Callable
from threading import Thread
import queue
import time

from src.utils.config import config
from src.utils.logger import logger

class SpeechRecognizer:
    """Speech recognition handler with VAD (Voice Activity Detection)."""
    
    def __init__(self):
        """Initialize speech recognizer."""
        self.recognizer = sr.Recognizer()
        self.microphone = None
        self.vad = webrtcvad.Vad(config.vad_aggressiveness)
        self.is_listening = False
        self.audio_queue = queue.Queue()
        self.callback: Optional[Callable[[str], None]] = None
        
        # Adjust for ambient noise
        self._adjust_for_ambient_noise()
        logger.info("Speech recognizer initialized")
    
    def _adjust_for_ambient_noise(self):
        """Adjust recognizer for ambient noise."""
        try:
            if self.microphone is None:
                self.microphone = sr.Microphone()
            
            with self.microphone as source:
                logger.info("Adjusting for ambient noise... Please wait.")
                self.recognizer.adjust_for_ambient_noise(source, duration=1)
                logger.info("Ambient noise adjustment complete")
        except Exception as e:
            logger.warning(f"Could not adjust for ambient noise: {e}")
    
    def listen_once(self, timeout: float = 5.0, phrase_time_limit: float = 10.0) -> Optional[str]:
        """
        Listen for a single phrase.
        
        Args:
            timeout: Maximum time to wait for speech to start
            phrase_time_limit: Maximum time for a phrase
            
        Returns:
            Recognized text or None
        """
        if self.microphone is None:
            self.microphone = sr.Microphone()
        
        try:
            with self.microphone as source:
                logger.info("Listening...")
                audio = self.recognizer.listen(
                    source,
                    timeout=timeout,
                    phrase_time_limit=phrase_time_limit
                )
            
            # Recognize speech
            try:
                text = self.recognizer.recognize_google(audio)
                logger.info(f"Recognized: {text}")
                return text
            except sr.UnknownValueError:
                logger.warning("Could not understand audio")
                return None
            except sr.RequestError as e:
                logger.error(f"Recognition service error: {e}")
                return None
                
        except sr.WaitTimeoutError:
            logger.info("No speech detected")
            return None
        except Exception as e:
            logger.error(f"Error in speech recognition: {e}")
            return None
    
    def start_continuous_listening(self, callback: Callable[[str], None]):
        """
        Start continuous listening with callback.
        
        Args:
            callback: Function to call when speech is recognized
        """
        self.callback = callback
        self.is_listening = True
        self.listening_thread = Thread(target=self._continuous_listen_loop, daemon=True)
        self.listening_thread.start()
        logger.info("Started continuous listening")
    
    def stop_continuous_listening(self):
        """Stop continuous listening."""
        self.is_listening = False
        logger.info("Stopped continuous listening")
    
    def _continuous_listen_loop(self):
        """Internal loop for continuous listening."""
        while self.is_listening:
            try:
                text = self.listen_once(timeout=1.0, phrase_time_limit=5.0)
                if text and self.callback:
                    self.callback(text)
            except Exception as e:
                logger.error(f"Error in continuous listening: {e}")
                time.sleep(0.5)
    
    def is_speaking(self, audio_data: bytes) -> bool:
        """
        Check if audio contains speech using VAD.
        
        Args:
            audio_data: Raw audio bytes
            
        Returns:
            True if speech detected
        """
        try:
            # VAD expects 16-bit PCM, 16kHz, mono
            return self.vad.is_speech(audio_data, sample_rate=16000)
        except Exception as e:
            logger.warning(f"VAD error: {e}")
            return True  # Default to assuming speech

