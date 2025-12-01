"""Script to download OpenVoice models."""
import os
import sys
import subprocess
from pathlib import Path
import urllib.request
import zipfile
import shutil

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.utils.config import config
from src.utils.logger import logger

def download_file(url: str, dest_path: Path):
    """Download a file from URL."""
    logger.info(f"Downloading {url} to {dest_path}...")
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    
    try:
        urllib.request.urlretrieve(url, dest_path)
        logger.info(f"Downloaded to {dest_path}")
        return True
    except Exception as e:
        logger.error(f"Error downloading {url}: {e}")
        return False

def extract_zip(zip_path: Path, extract_to: Path):
    """Extract zip file."""
    logger.info(f"Extracting {zip_path} to {extract_to}...")
    extract_to.mkdir(parents=True, exist_ok=True)
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)
        logger.info(f"Extracted to {extract_to}")
        return True
    except Exception as e:
        logger.error(f"Error extracting {zip_path}: {e}")
        return False

def setup_openvoice():
    """Set up OpenVoice models."""
    logger.info("Setting up OpenVoice models...")
    
    model_dir = Path(config.openvoice_model_path)
    model_dir.mkdir(parents=True, exist_ok=True)
    
    # Note: OpenVoice models need to be downloaded from their repository
    # This script provides instructions
    logger.info("""
    OpenVoice models need to be downloaded manually from:
    https://github.com/myshell-ai/OpenVoice
    
    Please follow these steps:
    1. Clone the OpenVoice repository:
       git clone https://github.com/myshell-ai/OpenVoice.git
    
    2. Download the model checkpoints from the repository
    
    3. Place the models in: {model_dir}
    
    Alternatively, you can use the fallback TTS system which doesn't require
    OpenVoice models.
    """.format(model_dir=model_dir))
    
    # Check if models exist
    checkpoints_dir = model_dir / "checkpoints"
    if checkpoints_dir.exists():
        logger.info("Model checkpoints directory found!")
        return True
    else:
        logger.warning("Model checkpoints not found. Using fallback TTS.")
        return False

def main():
    """Main setup function."""
    logger.info("Starting model download setup...")
    
    # Setup OpenVoice
    setup_openvoice()
    
    logger.info("Setup complete!")
    logger.info("You can now run the application with: python main.py")

if __name__ == "__main__":
    main()

