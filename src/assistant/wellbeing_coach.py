"""Mind wellbeing coaching responses and strategies."""
from typing import List, Dict, Optional
import random

from src.utils.config import config
from src.utils.logger import logger
from src.assistant.emotion_detector import EmotionDetector

class WellbeingCoach:
    """Provides mind wellbeing focused responses."""
    
    def __init__(self):
        """Initialize wellbeing coach."""
        self.emotion_detector = EmotionDetector()
        self.conversation_history: List[Dict] = []
        self.responses = self._build_response_templates()
        logger.info("Wellbeing coach initialized")
    
    def _build_response_templates(self) -> Dict[str, List[str]]:
        """Build response templates for different situations."""
        return {
            "greeting": [
                "Hello! I'm here to support you. How are you feeling today?",
                "Hi there! I'm Sprout, and I'm here to help with your mind wellbeing. What's on your mind?",
                "Welcome! I'm glad you're here. How can I support you today?",
                "Hello! Let's take a moment together. How are you doing?"
            ],
            "happy": [
                "That's wonderful to hear! I'm so glad you're feeling positive.",
                "It's beautiful to see you in a good space. What's contributing to this feeling?",
                "I'm happy for you! Celebrating these moments is important.",
                "That's fantastic! Positive moments like this are precious."
            ],
            "sad": [
                "I hear you, and I'm here with you. It's okay to feel this way.",
                "Thank you for sharing that with me. Your feelings are valid and important.",
                "I understand this is difficult. You're not alone in this.",
                "It takes courage to express these feelings. I'm here to support you."
            ],
            "anxious": [
                "I can sense you're feeling anxious. Let's take some deep breaths together.",
                "Anxiety can be overwhelming. Remember, this feeling will pass.",
                "You're safe here. Let's work through this together, one step at a time.",
                "I understand anxiety can be challenging. What helps you feel more grounded?"
            ],
            "tired": [
                "It sounds like you're feeling drained. Rest is important for your wellbeing.",
                "Being tired can affect how we feel. Have you been able to rest?",
                "I hear you're exhausted. Self-care is essential right now.",
                "Fatigue can be overwhelming. What would help you recharge?"
            ],
            "calm": [
                "It's beautiful that you're feeling calm and centered.",
                "I'm glad you're in a peaceful space. This is a good foundation.",
                "Calmness is a gift. How are you maintaining this sense of peace?",
                "That sense of calm is valuable. What's helping you stay grounded?"
            ],
            "encouragement": [
                "You're doing the best you can, and that's enough.",
                "Every step forward, no matter how small, is progress.",
                "You have strength within you, even when it doesn't feel that way.",
                "Remember, it's okay to not be okay. You're still moving forward.",
                "Your journey is unique, and you're navigating it with courage."
            ],
            "support": [
                "I'm here to listen and support you through this.",
                "You don't have to face this alone. I'm with you.",
                "Your wellbeing matters, and I'm here to help you nurture it.",
                "Together, we can explore ways to support your mind wellbeing."
            ],
            "closing": [
                "Take care of yourself. I'm here whenever you need support.",
                "Remember to be gentle with yourself. You're doing great.",
                "I'm glad we could connect. Take things one step at a time.",
                "You've got this. I'm here if you need to talk again."
            ]
        }
    
    def generate_response(
        self,
        user_input: str,
        conversation_context: Optional[List[Dict]] = None
    ) -> str:
        """
        Generate a wellbeing-focused response.
        
        Args:
            user_input: User's input text
            conversation_context: Previous conversation turns
            
        Returns:
            Response text
        """
        # Detect emotion
        emotion, confidence = self.emotion_detector.detect_emotion(user_input)
        wellbeing_level = self.emotion_detector.get_wellbeing_level(user_input)
        
        # Check for greetings
        if any(word in user_input.lower() for word in ["hello", "hi", "hey", "greetings"]):
            return random.choice(self.responses["greeting"])
        
        # Generate emotion-specific response
        if emotion in self.responses:
            base_response = random.choice(self.responses[emotion])
        else:
            base_response = random.choice(self.responses["support"])
        
        # Add encouragement if needed
        if wellbeing_level == "low" or emotion in ["sad", "anxious", "tired"]:
            encouragement = random.choice(self.responses["encouragement"])
            return f"{base_response} {encouragement}"
        
        return base_response
    
    def get_suggestions(self, emotion: str, wellbeing_level: str) -> List[str]:
        """
        Get wellbeing suggestions based on emotion and level.
        
        Args:
            emotion: Detected emotion
            wellbeing_level: Wellbeing level
            
        Returns:
            List of suggestions
        """
        suggestions = []
        
        if wellbeing_level == "low":
            suggestions = [
                "Take a few deep breaths - in through your nose, out through your mouth.",
                "Try a short walk, even just around your space.",
                "Remember to drink some water and take care of your basic needs.",
                "Consider writing down what you're feeling - it can help process emotions.",
                "You might want to try a brief meditation or mindfulness exercise."
            ]
        elif emotion == "anxious":
            suggestions = [
                "Try the 4-7-8 breathing technique: breathe in for 4, hold for 7, out for 8.",
                "Ground yourself by naming 5 things you can see, 4 you can touch, 3 you can hear.",
                "Remember that anxiety is temporary - this feeling will pass.",
                "Consider what's within your control right now, and focus on that."
            ]
        elif emotion == "tired":
            suggestions = [
                "Rest is important. Can you take a moment to pause?",
                "Consider what activities truly recharge you.",
                "Remember that rest is productive - you're not being lazy.",
                "Try to maintain a regular sleep schedule if possible."
            ]
        else:
            suggestions = [
                "Continue doing what's working for you.",
                "Consider what practices help maintain your sense of wellbeing.",
                "Remember to celebrate the positive moments.",
                "Stay connected with activities and people that support you."
            ]
        
        return suggestions
    
    def add_to_history(self, user_input: str, response: str, emotion: str):
        """Add conversation turn to history."""
        self.conversation_history.append({
            "user": user_input,
            "assistant": response,
            "emotion": emotion
        })
        
        # Keep history within limit
        if len(self.conversation_history) > config.max_conversation_history:
            self.conversation_history.pop(0)

