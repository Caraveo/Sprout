#!/bin/bash
# Start OpenVoice service using the dedicated virtual environment

cd "$(dirname "$0")/.."

# Fix OpenMP duplicate library error
export KMP_DUPLICATE_LIB_OK=TRUE
export OMP_NUM_THREADS=1

# Try to use openvoice_env if available, otherwise use system Python
if [ -d "openvoice_env" ]; then
    source openvoice_env/bin/activate
    PYTHON_CMD="python"
elif command -v /Users/caraveo/miniconda3/bin/python &> /dev/null; then
    PYTHON_CMD="/Users/caraveo/miniconda3/bin/python"
else
    PYTHON_CMD="python3"
fi

echo "🌱 Starting Sprout OpenVoice Service on port 6000..."
echo "Using Python: $($PYTHON_CMD --version 2>&1)"
echo "OpenVoice version: $($PYTHON_CMD -c 'import openvoice; print(openvoice.__version__ if hasattr(openvoice, "__version__") else "installed")' 2>/dev/null || echo 'checking...')"
echo ""

$PYTHON_CMD services/openvoice_service.py

