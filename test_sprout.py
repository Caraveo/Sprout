#!/usr/bin/env python3
"""Simple test script for Sprout components."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from src.assistant.conversation_engine import ConversationEngine
from src.visual.emoji_engine import EmojiEngine, EmotionCategory
from src.assistant.emotion_detector import EmotionDetector
from src.utils.logger import logger

def test_emoji_engine():
    """Test emoji engine."""
    print("\n=== Testing Emoji Engine ===")
    engine = EmojiEngine()
    
    test_texts = [
        "I'm feeling great today!",
        "I'm really anxious about tomorrow",
        "I feel calm and peaceful",
        "I'm exhausted and tired"
    ]
    
    for text in test_texts:
        emoji = engine.get_emoji_for_text(text)
        emotion = engine.analyze_text_emotion(text)
        print(f"Text: '{text}'")
        print(f"  Emoji: {emoji}")
        print(f"  Emotion: {emotion.value}")
        print()

def test_emotion_detector():
    """Test emotion detector."""
    print("\n=== Testing Emotion Detector ===")
    detector = EmotionDetector()
    
    test_texts = [
        "I'm so happy and excited!",
        "I feel sad and lonely",
        "I'm really anxious and worried",
        "I'm calm and relaxed"
    ]
    
    for text in test_texts:
        emotion, confidence = detector.detect_emotion(text)
        wellbeing = detector.get_wellbeing_level(text)
        print(f"Text: '{text}'")
        print(f"  Emotion: {emotion} (confidence: {confidence:.2f})")
        print(f"  Wellbeing: {wellbeing}")
        print()

def test_conversation_engine():
    """Test conversation engine."""
    print("\n=== Testing Conversation Engine ===")
    engine = ConversationEngine()
    engine.start_conversation(voice_enabled=False)
    
    test_inputs = [
        "Hello",
        "I'm feeling anxious today",
        "I had a great day!",
        "I'm tired and exhausted"
    ]
    
    for user_input in test_inputs:
        print(f"\nUser: {user_input}")
        result = engine.process_text_input(user_input)
        print(f"Sprout: {result.get('formatted_response', result.get('response', 'No response'))}")
        if result.get('suggestions'):
            print("Suggestions:")
            for suggestion in result['suggestions'][:2]:
                print(f"  - {suggestion}")
    
    engine.stop_conversation()
    print("\n=== Conversation Summary ===")
    summary = engine.get_conversation_summary()
    print(f"Total turns: {summary.get('total_turns', 0)}")
    print(f"Emotion distribution: {summary.get('emotion_distribution', {})}")

def main():
    """Run all tests."""
    print("🌱 Testing Sprout Voice Assistant Components\n")
    
    try:
        test_emoji_engine()
        test_emotion_detector()
        test_conversation_engine()
        print("\n✅ All tests completed!")
    except Exception as e:
        logger.error(f"Test failed: {e}")
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

