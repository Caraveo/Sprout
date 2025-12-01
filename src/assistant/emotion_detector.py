"""Emotion detection from text and voice."""
from typing import Dict, Optional, Tuple
import re
from collections import Counter

from src.utils.logger import logger

class EmotionDetector:
    """Detect emotions from text input."""
    
    def __init__(self):
        """Initialize emotion detector."""
        self.emotion_keywords = self._build_emotion_keywords()
        logger.info("Emotion detector initialized")
    
    def _build_emotion_keywords(self) -> Dict[str, Dict[str, float]]:
        """Build emotion keyword dictionary with weights."""
        return {
            "happy": {
                "happy": 1.0, "joy": 1.0, "excited": 0.9, "great": 0.8,
                "wonderful": 0.9, "amazing": 0.8, "good": 0.7, "better": 0.7,
                "smile": 0.8, "laugh": 0.9, "celebrate": 0.8, "success": 0.7
            },
            "sad": {
                "sad": 1.0, "depressed": 1.0, "down": 0.9, "unhappy": 0.9,
                "cry": 0.9, "tears": 0.9, "lonely": 0.8, "empty": 0.8,
                "hopeless": 0.9, "worthless": 0.9, "grief": 0.9
            },
            "anxious": {
                "anxious": 1.0, "anxiety": 1.0, "worried": 0.9, "nervous": 0.9,
                "panic": 1.0, "fear": 0.9, "scared": 0.9, "afraid": 0.8,
                "overwhelmed": 0.8, "stressed": 0.8, "tense": 0.7
            },
            "angry": {
                "angry": 1.0, "anger": 1.0, "mad": 0.9, "furious": 1.0,
                "irritated": 0.8, "frustrated": 0.8, "annoyed": 0.7,
                "rage": 1.0, "hate": 0.9
            },
            "calm": {
                "calm": 1.0, "peaceful": 0.9, "relaxed": 0.9, "serene": 0.9,
                "zen": 0.8, "centered": 0.8, "balanced": 0.7, "tranquil": 0.9
            },
            "tired": {
                "tired": 1.0, "exhausted": 0.9, "drained": 0.8, "fatigued": 0.9,
                "weary": 0.8, "sleepy": 0.7, "worn": 0.7, "burnout": 0.9
            },
            "grateful": {
                "grateful": 1.0, "gratitude": 1.0, "thankful": 0.9, "appreciate": 0.8,
                "blessed": 0.8, "fortunate": 0.7
            }
        }
    
    def detect_emotion(self, text: str) -> Tuple[str, float]:
        """
        Detect primary emotion from text.
        
        Args:
            text: Input text
            
        Returns:
            Tuple of (emotion_name, confidence_score)
        """
        text_lower = text.lower()
        emotion_scores = {}
        
        # Score each emotion
        for emotion, keywords in self.emotion_keywords.items():
            score = 0.0
            for keyword, weight in keywords.items():
                if keyword in text_lower:
                    score += weight
            emotion_scores[emotion] = score
        
        # Get primary emotion
        if not emotion_scores or max(emotion_scores.values()) == 0:
            return ("neutral", 0.0)
        
        primary_emotion = max(emotion_scores.items(), key=lambda x: x[1])
        
        # Normalize confidence (0-1)
        total_score = sum(emotion_scores.values())
        confidence = primary_emotion[1] / total_score if total_score > 0 else 0.0
        
        return (primary_emotion[0], min(confidence, 1.0))
    
    def detect_multiple_emotions(self, text: str, top_n: int = 3) -> Dict[str, float]:
        """
        Detect multiple emotions with confidence scores.
        
        Args:
            text: Input text
            top_n: Number of top emotions to return
            
        Returns:
            Dictionary of emotion -> confidence
        """
        text_lower = text.lower()
        emotion_scores = {}
        
        # Score each emotion
        for emotion, keywords in self.emotion_keywords.items():
            score = 0.0
            for keyword, weight in keywords.items():
                if keyword in text_lower:
                    score += weight
            if score > 0:
                emotion_scores[emotion] = score
        
        # Normalize scores
        total_score = sum(emotion_scores.values())
        if total_score > 0:
            emotion_scores = {k: v / total_score for k, v in emotion_scores.items()}
        
        # Sort and return top N
        sorted_emotions = sorted(emotion_scores.items(), key=lambda x: x[1], reverse=True)
        return dict(sorted_emotions[:top_n])
    
    def get_wellbeing_level(self, text: str) -> str:
        """
        Assess overall wellbeing level from text.
        
        Args:
            text: Input text
            
        Returns:
            Wellbeing level: "high", "medium", "low"
        """
        emotion, confidence = self.detect_emotion(text)
        
        positive_emotions = ["happy", "calm", "grateful"]
        negative_emotions = ["sad", "anxious", "angry", "tired"]
        
        if emotion in positive_emotions and confidence > 0.5:
            return "high"
        elif emotion in negative_emotions and confidence > 0.5:
            return "low"
        else:
            return "medium"

