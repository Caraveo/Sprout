"""Emoji engine for visual feedback based on conversation context."""
from typing import Dict, List, Optional, Tuple
import re
from enum import Enum

from src.utils.config import config
from src.utils.logger import logger

class EmotionCategory(Enum):
    """Emotion categories for emoji selection."""
    HAPPY = "happy"
    CALM = "calm"
    SUPPORTIVE = "supportive"
    EMPATHETIC = "empathetic"
    ENCOURAGING = "encouraging"
    THOUGHTFUL = "thoughtful"
    NEUTRAL = "neutral"
    CONCERNED = "concerned"

class EmojiEngine:
    """Engine for selecting and managing emoji feedback."""
    
    def __init__(self):
        """Initialize emoji engine."""
        self.emoji_map = self._build_emoji_map()
        self.current_emoji = "🌱"  # Sprout default
        logger.info("Emoji engine initialized")
    
    def _build_emoji_map(self) -> Dict[EmotionCategory, List[str]]:
        """Build mapping of emotions to emojis."""
        return {
            EmotionCategory.HAPPY: ["😊", "😄", "✨", "🌟", "💫", "🎉", "🌈"],
            EmotionCategory.CALM: ["🌱", "🌿", "🍃", "💚", "🧘", "☮️", "🕊️"],
            EmotionCategory.SUPPORTIVE: ["🤗", "💪", "🙌", "🤝", "💙", "❤️", "💜"],
            EmotionCategory.EMPATHETIC: ["💚", "🤲", "🌺", "🌸", "🌼", "🦋", "✨"],
            EmotionCategory.ENCOURAGING: ["🌟", "💫", "🚀", "⭐", "💪", "🎯", "🌈"],
            EmotionCategory.THOUGHTFUL: ["🤔", "💭", "🌙", "⭐", "🔮", "💫", "✨"],
            EmotionCategory.NEUTRAL: ["🌱", "💚", "🌿", "🍃", "✨"],
            EmotionCategory.CONCERNED: ["💙", "🤗", "🌺", "🤝", "💜", "🕊️"]
        }
    
    def get_emoji_for_emotion(self, emotion: EmotionCategory) -> str:
        """
        Get an emoji for a given emotion category.
        
        Args:
            emotion: Emotion category
            
        Returns:
            Emoji string
        """
        emojis = self.emoji_map.get(emotion, self.emoji_map[EmotionCategory.NEUTRAL])
        import random
        return random.choice(emojis)
    
    def analyze_text_emotion(self, text: str) -> EmotionCategory:
        """
        Analyze text to determine emotion category.
        
        Args:
            text: Input text
            
        Returns:
            Emotion category
        """
        text_lower = text.lower()
        
        # Positive/encouraging keywords
        positive_keywords = [
            "great", "wonderful", "amazing", "good", "happy", "excited",
            "better", "improve", "progress", "success", "achievement"
        ]
        
        # Concern/stress keywords
        concern_keywords = [
            "worried", "stressed", "anxious", "sad", "difficult", "hard",
            "struggle", "problem", "issue", "tired", "exhausted", "overwhelmed"
        ]
        
        # Calm/peaceful keywords
        calm_keywords = [
            "calm", "peaceful", "relaxed", "meditation", "breathing", "zen",
            "mindful", "present", "centered"
        ]
        
        # Count keyword matches
        positive_count = sum(1 for word in positive_keywords if word in text_lower)
        concern_count = sum(1 for word in concern_keywords if word in text_lower)
        calm_count = sum(1 for word in calm_keywords if word in text_lower)
        
        # Determine emotion
        if concern_count > positive_count and concern_count > 0:
            return EmotionCategory.CONCERNED
        elif positive_count > 0:
            return EmotionCategory.ENCOURAGING
        elif calm_count > 0:
            return EmotionCategory.CALM
        else:
            return EmotionCategory.NEUTRAL
    
    def get_emoji_for_text(self, text: str) -> str:
        """
        Get appropriate emoji for given text.
        
        Args:
            text: Input text
            
        Returns:
            Emoji string
        """
        emotion = self.analyze_text_emotion(text)
        emoji = self.get_emoji_for_emotion(emotion)
        self.current_emoji = emoji
        return emoji
    
    def get_emoji_sequence(self, emotion: EmotionCategory, count: int = 3) -> List[str]:
        """
        Get a sequence of emojis for animation.
        
        Args:
            emotion: Emotion category
            count: Number of emojis in sequence
            
        Returns:
            List of emoji strings
        """
        emojis = self.emoji_map.get(emotion, self.emoji_map[EmotionCategory.NEUTRAL])
        import random
        return [random.choice(emojis) for _ in range(count)]
    
    def get_response_emoji(self, user_text: str, assistant_text: str) -> str:
        """
        Get emoji based on both user input and assistant response.
        
        Args:
            user_text: User's input text
            assistant_text: Assistant's response text
            
        Returns:
            Emoji string
        """
        user_emotion = self.analyze_text_emotion(user_text)
        response_emotion = self.analyze_text_emotion(assistant_text)
        
        # If user is concerned, be empathetic/supportive
        if user_emotion == EmotionCategory.CONCERNED:
            return self.get_emoji_for_emotion(EmotionCategory.EMPATHETIC)
        
        # If response is encouraging, show encouragement
        if response_emotion == EmotionCategory.ENCOURAGING:
            return self.get_emoji_for_emotion(EmotionCategory.ENCOURAGING)
        
        # Default to calm/supportive
        return self.get_emoji_for_emotion(EmotionCategory.SUPPORTIVE)
    
    def format_text_with_emoji(self, text: str, emoji: Optional[str] = None) -> str:
        """
        Format text with emoji prefix.
        
        Args:
            text: Text to format
            emoji: Optional emoji (uses current if not provided)
            
        Returns:
            Formatted text with emoji
        """
        if not config.emoji_enabled:
            return text
        
        emoji = emoji or self.current_emoji
        return f"{emoji} {text}"

