#!/usr/bin/env python3
"""
OpenVoice Service for Sprout
Provides voice synthesis and cloning capabilities via HTTP API
"""

# Fix OpenMP duplicate library error
import os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
os.environ['OMP_NUM_THREADS'] = '1'

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import io
import sys
import json

# Add OpenVoice to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'openvoice'))

app = Flask(__name__)
CORS(app)

# Initialize OpenVoice (will be loaded on first request)
openvoice_model = None
tts_model = None

def load_openvoice():
    """Lazy load OpenVoice model"""
    global openvoice_model, tts_model
    
    if openvoice_model is not None:
        return
    
    try:
        print("🔧 Loading OpenVoice models...")
        
        # Import OpenVoice modules
        # Add openvoice to path first
        openvoice_path = os.path.join(os.path.dirname(__file__), '..', 'openvoice')
        if openvoice_path not in sys.path:
            sys.path.insert(0, openvoice_path)
        
        # Import se_extractor
        from openvoice.se_extractor import get_se
        
        # Import API classes
        from openvoice.api import BaseSpeakerTTS, ToneColorConverter
        
        # MeloTTS is optional - don't fail if not available
        try:
            from melo.api import TTS
            tts_model = TTS(language='EN', device='cpu')
            print("✅ MeloTTS loaded")
        except ImportError:
            print("⚠️ MeloTTS not available, will use base TTS only")
            TTS = None
            tts_model = None
        
        # Load models - check if checkpoints exist
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        ckpt_base = os.path.join(project_root, 'checkpoints', 'base_speakers', 'EN')
        ckpt_converter = os.path.join(project_root, 'checkpoints', 'converter')
        
        if not os.path.exists(ckpt_base):
            print(f"❌ Base speaker checkpoints not found at: {ckpt_base}")
            print("   Please download checkpoints from: https://github.com/myshell-ai/OpenVoice")
            raise FileNotFoundError(f"Checkpoints not found: {ckpt_base}")
        
        if not os.path.exists(ckpt_converter):
            print(f"❌ Converter checkpoints not found at: {ckpt_converter}")
            print("   Please download checkpoints from: https://github.com/myshell-ai/OpenVoice")
            raise FileNotFoundError(f"Checkpoints not found: {ckpt_converter}")
        
        device = 'cuda' if os.system('nvidia-smi') == 0 else 'cpu'
        print(f"🔧 Using device: {device}")
        
        print("   Loading BaseSpeakerTTS...")
        base_speaker_tts = BaseSpeakerTTS(f'{ckpt_base}/config.json', device=device)
        base_speaker_tts.load_ckpt(f'{ckpt_base}/checkpoint.pth')
        print("   ✅ BaseSpeakerTTS loaded")
        
        print("   Loading ToneColorConverter...")
        tone_color_converter = ToneColorConverter(
            f'{ckpt_converter}/config.json', device=device
        )
        tone_color_converter.load_ckpt(f'{ckpt_converter}/checkpoint.pth')
        print("   ✅ ToneColorConverter loaded")
        
        openvoice_model = {
            'base_speaker_tts': base_speaker_tts,
            'tone_color_converter': tone_color_converter,
            'device': device,
            'get_se': get_se  # Store the get_se function
        }
        
        print("✅ OpenVoice models loaded successfully!")
        
    except Exception as e:
        print(f"❌ OpenVoice loading failed: {e}")
        import traceback
        traceback.print_exc()
        openvoice_model = None

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'openvoice_loaded': openvoice_model is not None})

@app.route('/synthesize', methods=['POST'])
def synthesize():
    """Synthesize speech from text"""
    try:
        data = request.json
        text = data.get('text', '')
        language = data.get('language', 'en')
        style = data.get('style', 'default')
        
        if not text:
            return jsonify({'error': 'No text provided'}), 400
        
        # Try to load OpenVoice if not loaded
        if openvoice_model is None:
            load_openvoice()
        
        # Use OpenVoice if available
        if openvoice_model and openvoice_model.get('base_speaker_tts') is not None:
            from scipy.io.wavfile import write
            import numpy as np
            import tempfile
            
            base_speaker_tts = openvoice_model['base_speaker_tts']
            tone_color_converter = openvoice_model['tone_color_converter']
            get_se = openvoice_model['get_se']
            device = openvoice_model['device']
            
            # Generate base speech - try jon_reference first, then default
            script_dir = os.path.dirname(os.path.abspath(__file__))
            project_root = os.path.dirname(script_dir)
            
            src_path = os.path.join(project_root, 'resources', 'audio', 'jon_reference.wav')  # Jon's voice
            if not os.path.exists(src_path):
                src_path = os.path.join(project_root, 'resources', 'audio', 'reference.wav')  # Fallback reference
            if not os.path.exists(src_path):
                # No reference audio - use MeloTTS if available, otherwise use base speaker only
                if tts_model is not None:
                    # Use MeloTTS to generate base speech
                    speaker_ids = tts_model.hps.data.spk2id
                    speaker_id = speaker_ids.get('EN-US', 0)
                    
                    speed = 1.1  # 10% faster
                    tmp_src_path = tempfile.mktemp(suffix='.wav')
                    tts_model.tts_to_file(text, speaker_id, tmp_src_path, speed=speed)
                    
                    # Extract embeddings from generated audio
                    source_se, _ = get_se(tmp_src_path, tone_color_converter, vad=True)
                    target_se = source_se  # Use same embedding if no reference
                    
                    # Convert tone (will just pass through since src_se == tgt_se)
                    tgt_path = tempfile.mktemp(suffix='.wav')
                    encode_message = "@MyShell"
                    tone_color_converter.convert(
                        audio_src_path=tmp_src_path,
                        src_se=source_se,
                        tgt_se=target_se,
                        output_path=tgt_path,
                        message=encode_message
                    )
                    
                    # Read and return audio
                    with open(tgt_path, 'rb') as f:
                        audio_data = f.read()
                    
                    os.remove(tgt_path)
                    os.remove(tmp_src_path)
                    
                    return send_file(
                        io.BytesIO(audio_data),
                        mimetype='audio/wav',
                        as_attachment=False
                    )
                else:
                    # Fallback: use base speaker TTS only (no voice cloning)
                    tmp_src_path = tempfile.mktemp(suffix='.wav')
                    base_speaker_tts.tts(text, tmp_src_path, speaker='default', language='English', speed=1.1)  # 10% faster
                    
                    with open(tmp_src_path, 'rb') as f:
                        audio_data = f.read()
                    
                    os.remove(tmp_src_path)
                    
                    return send_file(
                        io.BytesIO(audio_data),
                        mimetype='audio/wav',
                        as_attachment=False
                    )
            else:
                # Use reference voice (Jon's voice)
                print(f"🎤 Using reference voice: {src_path}")
                
                # Step 1: Generate base speech from text
                tmp_src_path = tempfile.mktemp(suffix='.wav')
                base_speaker_tts.tts(text, tmp_src_path, speaker='default', language='English', speed=1.1)  # 10% faster
                
                # Step 2: Extract target speaker embedding from reference audio
                target_se, audio_name = get_se(src_path, tone_color_converter, vad=True)
                
                # Step 3: Load source speaker embedding (default English speaker)
                source_se_path = os.path.join(project_root, 'checkpoints', 'base_speakers', 'EN', 'en_default_se.pth')
                if not os.path.exists(source_se_path):
                    # Fallback: try to extract from generated audio (less ideal)
                    print("⚠️  en_default_se.pth not found, extracting from generated audio")
                    source_se, _ = get_se(tmp_src_path, tone_color_converter, vad=True)
                else:
                    import torch
                    source_se = torch.load(source_se_path, map_location=device)
                
                # Step 4: Convert tone color
                tgt_path = tempfile.mktemp(suffix='.wav')
                encode_message = "@MyShell"
                tone_color_converter.convert(
                    audio_src_path=tmp_src_path,
                    src_se=source_se,
                    tgt_se=target_se,
                    output_path=tgt_path,
                    message=encode_message
                )
                
                # Step 5: Read and return audio
                with open(tgt_path, 'rb') as f:
                    audio_data = f.read()
                
                # Cleanup
                os.remove(tgt_path)
                os.remove(tmp_src_path)
                
                return send_file(
                    io.BytesIO(audio_data),
                    mimetype='audio/wav',
                    as_attachment=False
                )
        else:
            # OpenVoice models failed to load - provide helpful error
            error_msg = "OpenVoice models not loaded"
            details = "Checkpoints missing or models failed to load. Check server console for details."
            
            print(f"❌ {error_msg}")
            print(f"   Details: {details}")
            print("   To fix:")
            print("   1. Run: ./download_checkpoints.sh for instructions")
            print("   2. Download checkpoints from: https://github.com/myshell-ai/OpenVoice")
            print("   3. Place in: checkpoints/base_speakers/EN/ and checkpoints/converter/")
            print("   4. Restart the service")
            
            return jsonify({
                'error': error_msg,
                'details': details,
                'help': 'Run ./download_checkpoints.sh for setup instructions'
            }), 503
            
    except Exception as e:
        print(f"❌ Synthesis error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/clone', methods=['POST'])
def clone_voice():
    """Clone voice from reference audio"""
    try:
        if 'audio' not in request.files:
            return jsonify({'error': 'No audio file provided'}), 400
        
        audio_file = request.files['audio']
        
        # Save reference audio
        reference_path = 'resources/audio/reference.wav'
        os.makedirs(os.path.dirname(reference_path), exist_ok=True)
        audio_file.save(reference_path)
        
        return jsonify({'status': 'success', 'message': 'Voice cloned successfully'})
        
    except Exception as e:
        print(f"❌ Voice cloning error: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    import socket
    
    # Always try to use port 6000 first (start script should have cleared it)
    port = 6000
    
    # Check if port is available
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex(('127.0.0.1', port))
    sock.close()
    
    if result == 0:
        # Port is in use, try to find alternative
        print(f"⚠️  Port 6000 is in use, trying alternative ports...")
        for alt_port in range(6001, 6010):
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex(('127.0.0.1', alt_port))
            sock.close()
            if result != 0:
                port = alt_port
                print(f"⚠️  Using port {port} instead")
                break
        else:
            print(f"❌ No available ports found (6000-6009)")
            sys.exit(1)
    
    print(f"🌱 Starting Sprout OpenVoice Service on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=False)

