#!/bin/bash

echo "🌱 Setting up Sprout..."

# Check macOS version
if [[ $(sw_vers -productVersion | cut -d. -f1) -lt 13 ]]; then
    echo "❌ macOS 13.0 or later is required"
    exit 1
fi

# Create necessary directories
mkdir -p resources/audio
mkdir -p logs
mkdir -p checkpoints

# Setup Python virtual environment for OpenVoice service
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install -q --upgrade pip
pip install -q -r services/requirements.txt

# Check if OpenVoice is cloned
if [ ! -d "openvoice" ]; then
    echo "📥 Cloning OpenVoice repository..."
    git clone https://github.com/myshell-ai/OpenVoice.git openvoice
else
    echo "✅ OpenVoice already cloned"
fi

# Build Swift package
echo "🔨 Building Swift package..."
swift build -c release

echo ""
echo "✅ Setup complete!"
echo ""
echo "To run Sprout:"
echo "  1. Start OpenVoice service: python services/openvoice_service.py"
echo "  2. Run Sprout: swift run -c release"
echo ""
echo "Note: You'll need to download OpenVoice checkpoints separately"
echo "See: https://github.com/myshell-ai/OpenVoice for instructions"

