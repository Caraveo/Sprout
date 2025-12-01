"""Main conversation engine coordinating all components."""
from typing import Optional, Dict, List
import threading

from src.utils.config import config
from src.utils.logger import logger
from src.assistant.wellbeing_coach import WellbeingCoach
from src.assistant.emotion_detector import EmotionDetector
from src.voice.tts_engine import TTSEngine
from src.voice.speech_recognition import SpeechRecognizer
from src.visual.emoji_engine import EmojiEngine, EmotionCategory

class ConversationEngine:
    """Main conversation engine for the voice assistant."""
    
    def __init__(self):
        """Initialize conversation engine."""
        self.coach = WellbeingCoach()
        self.emotion_detector = EmotionDetector()
        self.tts_engine = TTSEngine()
        self.speech_recognizer = SpeechRecognizer()
        self.emoji_engine = EmojiEngine()
        
        self.is_active = False
        self.conversation_active = False
        self.current_emotion = "neutral"
        
        logger.info("Conversation engine initialized")
    
    def start_conversation(self, voice_enabled: bool = True):
        """
        Start a conversation session.
        
        Args:
            voice_enabled: Whether to use voice input/output
        """
        self.is_active = True
        self.conversation_active = True
        self.voice_enabled = voice_enabled
        
        if voice_enabled:
            # Start continuous listening
            self.speech_recognizer.start_continuous_listening(self._on_speech_recognized)
            logger.info("Started voice conversation")
        else:
            logger.info("Started text conversation")
    
    def stop_conversation(self):
        """Stop the conversation session."""
        self.is_active = False
        self.conversation_active = False
        
        if self.voice_enabled:
            self.speech_recognizer.stop_continuous_listening()
        
        logger.info("Stopped conversation")
    
    def process_text_input(self, text: str) -> Dict:
        """
        Process text input and generate response.
        
        Args:
            text: User input text
            
        Returns:
            Dictionary with response, emoji, and metadata
        """
        if not self.is_active:
            return {"error": "Conversation not active"}
        
        # Detect emotion
        emotion, confidence = self.emotion_detector.detect_emotion(text)
        self.current_emotion = emotion
        wellbeing_level = self.emotion_detector.get_wellbeing_level(text)
        
        # Generate response
        response = self.coach.generate_response(text)
        
        # Get appropriate emoji
        emoji = self.emoji_engine.get_response_emoji(text, response)
        
        # Add to history
        self.coach.add_to_history(text, response, emotion)
        
        # Get suggestions if needed
        suggestions = []
        if wellbeing_level == "low" or confidence > 0.6:
            suggestions = self.coach.get_suggestions(emotion, wellbeing_level)
        
        result = {
            "response": response,
            "emoji": emoji,
            "emotion": emotion,
            "confidence": confidence,
            "wellbeing_level": wellbeing_level,
            "suggestions": suggestions,
            "formatted_response": self.emoji_engine.format_text_with_emoji(response, emoji)
        }
        
        return result
    
    def process_voice_input(self, text: str) -> Dict:
        """
        Process voice input, generate response, and speak it.
        
        Args:
            text: Recognized speech text
            
        Returns:
            Response dictionary
        """
        # Process text
        result = self.process_text_input(text)
        
        if "error" not in result:
            # Speak the response
            if self.voice_enabled and self.tts_engine:
                try:
                    audio = self.tts_engine.speak(
                        result["response"],
                        language="English",
                        emotion=self.current_emotion
                    )
                    if audio is not None:
                        self.tts_engine.play_audio(audio)
                except Exception as e:
                    logger.error(f"Error in TTS: {e}")
        
        return result
    
    def _on_speech_recognized(self, text: str):
        """Callback for when speech is recognized."""
        if self.conversation_active:
            logger.info(f"Recognized speech: {text}")
            result = self.process_voice_input(text)
            logger.info(f"Response: {result.get('response', 'No response')}")
    
    def get_conversation_summary(self) -> Dict:
        """
        Get summary of current conversation.
        
        Returns:
            Summary dictionary
        """
        if not self.coach.conversation_history:
            return {"message": "No conversation history"}
        
        emotions = [turn["emotion"] for turn in self.coach.conversation_history]
        emotion_counts = {}
        for emotion in emotions:
            emotion_counts[emotion] = emotion_counts.get(emotion, 0) + 1
        
        return {
            "total_turns": len(self.coach.conversation_history),
            "emotion_distribution": emotion_counts,
            "current_emotion": self.current_emotion
        }
    
    def reset_conversation(self):
        """Reset conversation history."""
        self.coach.conversation_history = []
        self.current_emotion = "neutral"
        logger.info("Conversation reset")

