#!/bin/bash
# Test all voice styles quickly

echo "🎤 Testing all OpenVoice styles..."
echo "=================================="
echo ""

TEST_TEXT="Hello Seedling! This is a test."

for style in default excited friendly cheerful sad angry terrified shouting whispering; do
    echo "Testing: $style"
    python3 test_voice_styles.py "$style" "$TEST_TEXT"
    echo ""
    sleep 1  # Small delay between requests
done

echo "✅ All styles tested!"
echo "📁 Check test_voice_*.wav files"

