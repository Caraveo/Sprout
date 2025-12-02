#!/usr/bin/env python3
"""
Voice Training Utility for Sprout
Builds default.voice file for OpenVoice training
"""

import os
import sys
import json
from pydub import AudioSegment
import tempfile

def ensure_resources_dir():
    """Ensure resources/audio directory exists"""
    audio_dir = os.path.join("resources", "audio")
    os.makedirs(audio_dir, exist_ok=True)
    return audio_dir

def convert_to_training_format(input_path, output_path, sample_rate=22050, channels=1):
    """Convert audio to training format (22050 Hz, mono)"""
    try:
        audio = AudioSegment.from_file(input_path)
        audio = audio.set_frame_rate(sample_rate).set_channels(channels)
        audio.export(output_path, format="wav")
        print(f"✅ Converted to training format: {output_path}")
        return True
    except Exception as e:
        print(f"❌ Error converting audio: {e}")
        return False

def create_voice_file(audio_path, metadata):
    """Create default.voice file with metadata"""
    voice_data = {
        "audio_path": audio_path,
        "metadata": metadata,
        "format": "wav",
        "sample_rate": 22050,
        "channels": 1
    }
    
    voice_file_path = os.path.join("resources", "audio", "default.voice")
    
    try:
        with open(voice_file_path, 'w') as f:
            json.dump(voice_data, f, indent=2)
        print(f"✅ Created voice file: {voice_file_path}")
        return True
    except Exception as e:
        print(f"❌ Error creating voice file: {e}")
        return False

def main():
    print("🌱 Sprout Voice Training Utility")
    print("=" * 50)
    print()
    
    if len(sys.argv) < 2:
        print("Usage: python train.py <audio_file> [metadata_json]")
        print()
        print("Examples:")
        print("  python train.py recording.wav")
        print("  python train.py recording.wav '{\"name\":\"John\",\"gender\":\"male\"}'")
        sys.exit(1)
    
    audio_file = sys.argv[1]
    metadata = {}
    
    if len(sys.argv) > 2:
        try:
            metadata = json.loads(sys.argv[2])
        except:
            print("⚠️  Invalid metadata JSON, using defaults")
    
    if not os.path.exists(audio_file):
        print(f"❌ Audio file not found: {audio_file}")
        sys.exit(1)
    
    # Ensure resources directory exists
    audio_dir = ensure_resources_dir()
    
    # Convert to training format
    output_path = os.path.join(audio_dir, "default_voice.wav")
    if convert_to_training_format(audio_file, output_path):
        # Create voice file
        if create_voice_file(output_path, metadata):
            print()
            print("✅ Voice training complete!")
            print(f"   Voice file: {output_path}")
            print(f"   Metadata: {metadata}")
            print()
            print("🌱 Sprout will use this voice for all responses!")
        else:
            sys.exit(1)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()

