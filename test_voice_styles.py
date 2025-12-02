#!/usr/bin/env python3
"""
Test OpenVoice voice styles from command line
Usage: python test_voice_styles.py [style] [text]
"""

import sys
import requests
import json
import os
import socket

def find_openvoice_port():
    """Find which port OpenVoice service is running on"""
    for port in range(6000, 6010):
        try:
            response = requests.get(f"http://localhost:{port}/health", timeout=1)
            if response.status_code == 200:
                return port
        except:
            continue
    return None

def test_voice_style(style="default", text="Hello Seedling! This is a test of the voice style."):
    """Test a voice style with OpenVoice service"""
    
    # Find the service port
    port = find_openvoice_port()
    if port is None:
        print("❌ OpenVoice service not found on ports 6000-6009")
        print("   Make sure to start it: ./services/start_openvoice.sh")
        return False
    
    print(f"✅ Found OpenVoice service on port {port}")
    print(f"🎤 Testing voice style: {style}")
    print(f"📝 Text: {text}")
    print()
    
    # Make synthesis request
    url = f"http://localhost:{port}/synthesize"
    payload = {
        "text": text,
        "language": "en",
        "style": style
    }
    
    try:
        print("⏳ Requesting synthesis...")
        response = requests.post(url, json=payload, timeout=30)
        
        if response.status_code == 200:
            # Save audio to file
            output_file = f"test_voice_{style}.wav"
            with open(output_file, 'wb') as f:
                f.write(response.content)
            
            file_size = len(response.content)
            print(f"✅ Synthesis successful!")
            print(f"📁 Saved to: {output_file} ({file_size:,} bytes)")
            print(f"🔊 Play with: afplay {output_file}")
            return True
        else:
            print(f"❌ Synthesis failed with status {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data}")
            except:
                print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
        return False

def list_available_styles():
    """List all available voice styles"""
    styles = [
        "default",
        "excited",
        "friendly",
        "cheerful",
        "sad",
        "angry",
        "terrified",
        "shouting",
        "whispering"
    ]
    
    print("Available voice styles:")
    print("=" * 50)
    for style in styles:
        print(f"  • {style}")
    print()

def main():
    if len(sys.argv) > 1 and sys.argv[1] in ["-h", "--help", "help"]:
        print("OpenVoice Style Tester")
        print("=" * 50)
        print("Usage:")
        print("  python test_voice_styles.py [style] [text]")
        print()
        print("Examples:")
        print("  python test_voice_styles.py")
        print("  python test_voice_styles.py excited")
        print("  python test_voice_styles.py cheerful 'Hello! This is cheerful!'")
        print("  python test_voice_styles.py list")
        print()
        list_available_styles()
        return
    
    # List styles if requested
    if len(sys.argv) > 1 and sys.argv[1] == "list":
        list_available_styles()
        return
    
    # Get style and text from command line
    style = sys.argv[1] if len(sys.argv) > 1 else "default"
    text = sys.argv[2] if len(sys.argv) > 2 else "Hello Seedling! This is a test of the voice style."
    
    # Validate style
    valid_styles = ["default", "excited", "friendly", "cheerful", "sad", "angry", "terrified", "shouting", "whispering"]
    if style not in valid_styles:
        print(f"❌ Invalid style: {style}")
        print()
        list_available_styles()
        return
    
    # Test the voice style
    success = test_voice_style(style, text)
    
    if success:
        print()
        print("💡 Tip: Test multiple styles:")
        print("   for style in default excited friendly cheerful sad; do")
        print("     python test_voice_styles.py $style 'Hello Seedling!'")
        print("   done")

if __name__ == "__main__":
    main()

