#!/bin/bash
# Test OpenVoice voice styles using curl (no Python dependencies)

STYLE="${1:-default}"
TEXT="${2:-Hello Seedling! This is a test of the voice style.}"

# Find OpenVoice service port
find_port() {
    for port in {6000..6009}; do
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            echo $port
            return 0
        fi
    done
    return 1
}

PORT=$(find_port)

if [ -z "$PORT" ]; then
    echo "❌ OpenVoice service not found on ports 6000-6009"
    echo "   Make sure to start it: ./services/start_openvoice.sh"
    exit 1
fi

echo "✅ Found OpenVoice service on port $PORT"
echo "🎤 Testing voice style: $STYLE"
echo "📝 Text: $TEXT"
echo ""

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "text": "$TEXT",
  "language": "en",
  "style": "$STYLE"
}
EOF
)

# Make request and save to file
OUTPUT_FILE="test_voice_${STYLE}.wav"

echo "⏳ Requesting synthesis..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "http://localhost:$PORT/synthesize" \
    -o "$OUTPUT_FILE")

if [ "$HTTP_CODE" -eq 200 ]; then
    FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    echo "✅ Synthesis successful!"
    echo "📁 Saved to: $OUTPUT_FILE ($FILE_SIZE bytes)"
    echo "🔊 Play with: afplay $OUTPUT_FILE"
else
    echo "❌ Synthesis failed with HTTP code: $HTTP_CODE"
    if [ -f "$OUTPUT_FILE" ]; then
        echo "Response:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"
    fi
    exit 1
fi

