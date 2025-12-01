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

# OpenVoice V2 checkpoints zip file (converter only - uses MeloTTS for base)
CHECKPOINTS_V2_URL="https://myshell-public-repo-host.s3.amazonaws.com/openvoice/checkpoints_v2_0417.zip"
# OpenVoice V1 checkpoints zip file (includes base_speakers/EN)
CHECKPOINTS_V1_URL="https://myshell-public-repo-host.s3.amazonaws.com/openvoice/checkpoints_1226.zip"
ZIP_FILE_V2="checkpoints_v2_0417.zip"
ZIP_FILE_V1="checkpoints_1226.zip"

echo "📦 Downloading OpenVoice checkpoints..."
echo "   We need both V1 (base speakers) and V2 (converter) checkpoints"
echo "   This will download ~900MB total, please be patient..."
echo ""

# Download V1 checkpoints (for base_speakers/EN)
echo "   Step 1/2: Downloading V1 checkpoints (base speakers)..."
$DOWNLOAD_CMD $DOWNLOAD_FLAGS "$ZIP_FILE_V1" "$CHECKPOINTS_V1_URL"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download V1 checkpoints"
    echo "   Please try downloading manually from:"
    echo "   $CHECKPOINTS_V1_URL"
    exit 1
fi

# Download V2 checkpoints (for converter)
echo ""
echo "   Step 2/2: Downloading V2 checkpoints (converter)..."
$DOWNLOAD_CMD $DOWNLOAD_FLAGS "$ZIP_FILE_V2" "$CHECKPOINTS_V2_URL"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download V2 checkpoints"
    echo "   Please try downloading manually from:"
    echo "   $CHECKPOINTS_V2_URL"
    rm -f "$ZIP_FILE_V1"
    exit 1
fi

echo ""
echo "📦 Extracting checkpoints..."

# Extract V1 zip file (base_speakers/EN)
echo "   Extracting V1 checkpoints..."
unzip -q -o "$ZIP_FILE_V1" -d .

# Extract V2 zip file (converter)
echo "   Extracting V2 checkpoints..."
unzip -q -o "$ZIP_FILE_V2" -d .

if [ $? -ne 0 ]; then
    echo "❌ Failed to extract checkpoints"
    rm -f "$ZIP_FILE_V1" "$ZIP_FILE_V2"
    exit 1
fi

# Organize checkpoints (service expects this structure)
echo "   Organizing checkpoints..."

# Create directories
mkdir -p checkpoints/base_speakers/EN
mkdir -p checkpoints/converter

# Copy V1 base_speakers/EN files
if [ -d "checkpoints/base_speakers/EN" ] && [ -f "checkpoints/base_speakers/EN/config.json" ]; then
    echo "   ✅ V1 base_speakers/EN already in place"
elif [ -f "checkpoints/base_speakers/EN/config.json" ]; then
    echo "   ✅ Found base_speakers/EN/config.json"
else
    # Try to find it in extracted files
    if [ -f "checkpoints/base_speakers/EN/config.json" ]; then
        echo "   ✅ Found base_speakers/EN/config.json"
    else
        echo "   ⚠️  base_speakers/EN/config.json not found, checking extracted files..."
        find . -name "config.json" -path "*/base_speakers/EN/*" | head -1 | xargs -I {} cp {} checkpoints/base_speakers/EN/ 2>/dev/null
        find . -name "checkpoint.pth" -path "*/base_speakers/EN/*" | head -1 | xargs -I {} cp {} checkpoints/base_speakers/EN/ 2>/dev/null
    fi
fi

# Copy V2 converter files
if [ -d "checkpoints_v2/converter" ]; then
    if [ -f "checkpoints_v2/converter/config.json" ]; then
        cp checkpoints_v2/converter/config.json checkpoints/converter/
        echo "   ✅ Copied converter/config.json"
    fi
    if [ -f "checkpoints_v2/converter/checkpoint.pth" ]; then
        cp checkpoints_v2/converter/checkpoint.pth checkpoints/converter/
        echo "   ✅ Copied converter/checkpoint.pth"
    fi
fi

# Clean up
echo "   Cleaning up temporary files..."
rm -rf checkpoints_v2
rm -f "$ZIP_FILE_V1" "$ZIP_FILE_V2"

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
