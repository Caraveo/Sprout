#!/bin/bash
# Setup script for Sprout voice assistant

set -e

echo "🌱 Setting up Sprout Voice Assistant..."

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "Python version: $python_version"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Create necessary directories
echo "Creating directories..."
mkdir -p models
mkdir -p resources/audio
mkdir -p logs
mkdir -p static
mkdir -p templates

# Run model setup script
echo "Setting up models..."
python scripts/download_models.py

echo ""
echo "✅ Setup complete!"
echo ""
echo "To use Sprout:"
echo "  1. Activate virtual environment: source venv/bin/activate"
echo "  2. Run CLI: python main.py"
echo "  3. Or run web app: python app.py"
echo ""

