#!/bin/bash
# Start OpenVoice service using the dedicated virtual environment

cd "$(dirname "$0")/.."

if [ ! -d "openvoice_env" ]; then
    echo "❌ OpenVoice environment not found. Please run setup first."
    exit 1
fi

source openvoice_env/bin/activate

echo "🌱 Starting Sprout OpenVoice Service on port 6000..."
echo "Using Python: $(which python)"
echo "OpenVoice version: $(python -c 'import openvoice; print(openvoice.__version__ if hasattr(openvoice, "__version__") else "installed")' 2>/dev/null || echo 'checking...')"
echo ""

python services/openvoice_service.py

