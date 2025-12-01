#!/bin/bash
# Download OpenVoice checkpoints

cd "$(dirname "$0")"

echo "🌱 Downloading OpenVoice Checkpoints"
echo "======================================"
echo ""

# Create checkpoints directory structure
mkdir -p checkpoints/base_speakers/EN
mkdir -p checkpoints/converter

echo "📦 You need to download OpenVoice checkpoints manually:"
echo ""
echo "1. Base Speaker TTS (EN):"
echo "   - Download from: https://github.com/myshell-ai/OpenVoice"
echo "   - Place files in: checkpoints/base_speakers/EN/"
echo "   - Required files:"
echo "     * config.json"
echo "     * checkpoint.pth"
echo ""
echo "2. Tone Color Converter:"
echo "   - Download from: https://github.com/myshell-ai/OpenVoice"
echo "   - Place files in: checkpoints/converter/"
echo "   - Required files:"
echo "     * config.json"
echo "     * checkpoint.pth"
echo ""
echo "📖 See OpenVoice README for download links:"
echo "   https://github.com/myshell-ai/OpenVoice#installation"
echo ""
echo "After downloading, restart the OpenVoice service:"
echo "   ./services/start_openvoice.sh"

