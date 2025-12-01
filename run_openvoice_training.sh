#!/bin/bash
# Script to run OpenVoice training with correct Python environment

cd "$(dirname "$0")"

# Set PYTHONPATH to include openvoice_env packages
export PYTHONPATH="openvoice_env/lib/python3.11/site-packages:$PYTHONPATH"

# Try to find Python 3.11 in openvoice_env
if [ -f "openvoice_env/bin/python3.11" ]; then
    echo "🌱 Using openvoice_env Python 3.11..."
    openvoice_env/bin/python3.11 open.py
elif [ -f "openvoice_env/bin/python" ]; then
    echo "🌱 Using openvoice_env Python..."
    openvoice_env/bin/python open.py
elif command -v python3.11 &> /dev/null; then
    echo "🌱 Using system Python 3.11 with openvoice_env packages..."
    python3.11 open.py
else
    echo "❌ Python 3.11 not found. Please activate openvoice_env first:"
    echo "   source openvoice_env/bin/activate"
    echo "   python open.py"
    exit 1
fi

