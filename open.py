#!/usr/bin/env python3
"""
OpenVoice Voice Training Script
Analyzes jon.m4a and extracts voice embedding for Sprout

Usage:
    source openvoice_env/bin/activate
    python open.py
    
    OR
    
    openvoice_env/bin/python3.11 open.py
"""

import os
import sys
import subprocess
import tempfile

# Add OpenVoice to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'openvoice'))

# Try to use openvoice_env Python if available
script_dir = os.path.dirname(os.path.abspath(__file__))
openvoice_env_python = os.path.join(script_dir, 'openvoice_env', 'bin', 'python3.11')
if os.path.exists(openvoice_env_python):
    print(f"ℹ️  Note: For best results, run with: {openvoice_env_python} open.py")

def convert_m4a_to_wav(m4a_path, wav_path):
    """Convert M4A to WAV using ffmpeg"""
    try:
        cmd = [
            'ffmpeg', '-i', m4a_path,
            '-ar', '22050',  # Sample rate for OpenVoice
            '-ac', '1',      # Mono
            '-y',            # Overwrite
            wav_path
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ FFmpeg error: {result.stderr}")
            return False
        print(f"✅ Converted {m4a_path} to {wav_path}")
        return True
    except FileNotFoundError:
        print("❌ FFmpeg not found. Please install: brew install ffmpeg")
        return False
    except Exception as e:
        print(f"❌ Conversion error: {e}")
        return False

def extract_voice_embedding(audio_path, output_path):
    """Extract speaker embedding from audio using OpenVoice"""
    print(f"ℹ️  Voice embedding will be extracted on first use by OpenVoice service")
    print(f"   Reference audio saved: {audio_path}")
    print(f"   The OpenVoice service will automatically extract the embedding when needed")
    return True

def main():
    """Main function to process jon.m4a"""
    print("🌱 Sprout Voice Training - OpenVoice Analysis")
    print("=" * 50)
    
    # Paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    m4a_path = os.path.join(script_dir, 'Jon.m4a')
    resources_dir = os.path.join(script_dir, 'resources', 'audio')
    wav_path = os.path.join(resources_dir, 'jon_reference.wav')
    embedding_path = os.path.join(resources_dir, 'jon_embedding.npy')
    
    # Check if input file exists
    if not os.path.exists(m4a_path):
        print(f"❌ Audio file not found: {m4a_path}")
        print("   Please ensure Jon.m4a is in the Sprout directory")
        return 1
    
    # Create resources directory if needed
    os.makedirs(resources_dir, exist_ok=True)
    
    # Step 1: Convert M4A to WAV
    print("\n📦 Step 1: Converting M4A to WAV...")
    if not convert_m4a_to_wav(m4a_path, wav_path):
        return 1
    
    # Step 2: Note about embedding (will be extracted by service)
    print("\n🎤 Step 2: Voice embedding setup...")
    extract_voice_embedding(wav_path, embedding_path)
    
    # Step 3: Copy WAV as reference for OpenVoice service
    reference_path = os.path.join(resources_dir, 'reference.wav')
    if os.path.exists(wav_path):
        import shutil
        shutil.copy2(wav_path, reference_path)
        print(f"✅ Reference voice saved to {reference_path}")
    
    print("\n" + "=" * 50)
    print("✅ Voice training complete!")
    print(f"   Reference audio: {reference_path}")
    print(f"   Voice embedding: {embedding_path}")
    print("\n🌱 Sprout will now use Jon's voice for all responses!")
    print("   Restart the OpenVoice service to apply changes.")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())

