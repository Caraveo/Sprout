#!/bin/bash
# Automatically download OpenVoice V2 checkpoints

cd "$(dirname "$0")"

echo "🌱 Downloading OpenVoice V2 Checkpoints"
echo "========================================"
echo ""

# Check if unzip is available
if ! command -v unzip &> /dev/null; then
    echo "❌ unzip not found. Please install: brew install unzip"
    exit 1
fi

# Check if wget or curl is available
if command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget"
    DOWNLOAD_FLAGS="--show-progress -O"
elif command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl"
    DOWNLOAD_FLAGS="-L --progress-bar -o"
else
    echo "❌ Neither wget nor curl found. Please install one of them."
    exit 1
fi

# OpenVoice V2 checkpoints zip file
CHECKPOINTS_URL="https://myshell-public-repo-host.s3.amazonaws.com/openvoice/checkpoints_v2_0417.zip"
ZIP_FILE="checkpoints_v2_0417.zip"

echo "📦 Downloading OpenVoice V2 checkpoints..."
echo "   This is a large file (~700MB), please be patient..."
echo ""

# Download the zip file
$DOWNLOAD_CMD $DOWNLOAD_FLAGS "$ZIP_FILE" "$CHECKPOINTS_URL"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download checkpoints"
    echo "   Please try downloading manually from:"
    echo "   $CHECKPOINTS_URL"
    exit 1
fi

echo ""
echo "📦 Extracting checkpoints..."

# Extract the zip file
unzip -q "$ZIP_FILE" -d .

if [ $? -ne 0 ]; then
    echo "❌ Failed to extract checkpoints"
    rm -f "$ZIP_FILE"
    exit 1
fi

# Move checkpoints_v2 to checkpoints (service expects this structure)
if [ -d "checkpoints_v2" ]; then
    echo "   Moving checkpoints to correct location..."
    
    # Create base_speakers/EN directory if needed
    mkdir -p checkpoints/base_speakers/EN
    mkdir -p checkpoints/converter
    
    # Copy files
    if [ -f "checkpoints_v2/base_speakers/EN/config.json" ]; then
        cp checkpoints_v2/base_speakers/EN/config.json checkpoints/base_speakers/EN/
        echo "   ✅ Copied base_speakers/EN/config.json"
    fi
    
    if [ -f "checkpoints_v2/base_speakers/EN/checkpoint.pth" ]; then
        cp checkpoints_v2/base_speakers/EN/checkpoint.pth checkpoints/base_speakers/EN/
        echo "   ✅ Copied base_speakers/EN/checkpoint.pth"
    fi
    
    if [ -f "checkpoints_v2/converter/config.json" ]; then
        cp checkpoints_v2/converter/config.json checkpoints/converter/
        echo "   ✅ Copied converter/config.json"
    fi
    
    if [ -f "checkpoints_v2/converter/checkpoint.pth" ]; then
        cp checkpoints_v2/converter/checkpoint.pth checkpoints/converter/
        echo "   ✅ Copied converter/checkpoint.pth"
    fi
    
    # Clean up
    echo "   Cleaning up..."
    rm -rf checkpoints_v2
    rm -f "$ZIP_FILE"
else
    echo "⚠️  checkpoints_v2 directory not found in zip file"
    echo "   Checking zip contents..."
    unzip -l "$ZIP_FILE" | head -20
    rm -f "$ZIP_FILE"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ Download and extraction complete!"
echo ""

# Verify files
MISSING_FILES=0

if [ ! -f "checkpoints/base_speakers/EN/config.json" ]; then
    echo "❌ Missing: checkpoints/base_speakers/EN/config.json"
    MISSING_FILES=1
fi

if [ ! -f "checkpoints/base_speakers/EN/checkpoint.pth" ]; then
    echo "❌ Missing: checkpoints/base_speakers/EN/checkpoint.pth"
    MISSING_FILES=1
fi

if [ ! -f "checkpoints/converter/config.json" ]; then
    echo "❌ Missing: checkpoints/converter/config.json"
    MISSING_FILES=1
fi

if [ ! -f "checkpoints/converter/checkpoint.pth" ]; then
    echo "❌ Missing: checkpoints/converter/checkpoint.pth"
    MISSING_FILES=1
fi

if [ $MISSING_FILES -eq 0 ]; then
    echo "✅ All checkpoints verified!"
    echo ""
    echo "🌱 You can now restart the OpenVoice service:"
    echo "   ./services/start_openvoice.sh"
    echo ""
    echo "Sprout will automatically use Jon's voice once the service is running!"
    echo ""
    echo "💡 The service will load models on first use (may take a minute)."
else
    echo ""
    echo "⚠️  Some files are missing. Please check the extraction."
    exit 1
fi
