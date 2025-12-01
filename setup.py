"""Setup script for Sprout."""
from setuptools import setup, find_packages
from pathlib import Path

# Read README
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text() if readme_file.exists() else ""

setup(
    name="sprout",
    version="1.0.0",
    description="Mind Wellbeing Voice Assistant with OpenVoice",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Sprout Team",
    packages=find_packages(),
    python_requires=">=3.8",
    install_requires=[
        "torch>=2.0.0",
        "torchaudio>=2.0.0",
        "numpy>=1.24.0",
        "scipy>=1.10.0",
        "librosa>=0.10.0",
        "soundfile>=0.12.0",
        "speechrecognition>=3.10.0",
        "pyaudio>=0.2.11",
        "pydub>=0.25.1",
        "webrtcvad>=2.0.10",
        "transformers>=4.30.0",
        "sentence-transformers>=2.2.0",
        "flask>=2.3.0",
        "flask-socketio>=5.3.0",
        "flask-cors>=4.0.0",
        "python-dotenv>=1.0.0",
        "requests>=2.31.0",
        "colorama>=0.4.6",
        "rich>=13.0.0",
        "opencv-python>=4.8.0",
        "pandas>=2.0.0",
        "python-dateutil>=2.8.2",
        "pyyaml>=6.0",
    ],
    entry_points={
        "console_scripts": [
            "sprout=main:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)

