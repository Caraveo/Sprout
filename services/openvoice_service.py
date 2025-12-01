#!/usr/bin/env python3
"""
OpenVoice Service for Sprout
Provides voice synthesis and cloning capabilities via HTTP API
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import io
import os
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
        from openvoice import se_extractor
        from openvoice.api import BaseSpeakerTTS, ToneColorConverter
        from melo.api import TTS
        
        # Load models
        ckpt_base = 'checkpoints/base_speakers/EN'
        ckpt_converter = 'checkpoints/converter'
        device = 'cuda' if os.system('nvidia-smi') == 0 else 'cpu'
        
        base_speaker_tts = BaseSpeakerTTS(f'{ckpt_base}/config.json', device=device)
        base_speaker_tts.load_ckpt(f'{ckpt_base}/checkpoint.pth')
        
        tone_color_converter = ToneColorConverter(
            f'{ckpt_converter}/config.json', device=device
        )
        tone_color_converter.load_ckpt(f'{ckpt_converter}/checkpoint.pth')
        
        # Load MeloTTS for base TTS
        tts_model = TTS(language='EN', device=device)
        
        openvoice_model = {
            'base_speaker_tts': base_speaker_tts,
            'tone_color_converter': tone_color_converter,
            'device': device
        }
        
        print("✅ OpenVoice models loaded successfully")
        
    except Exception as e:
        print(f"⚠️ OpenVoice not available, using fallback: {e}")
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
        if openvoice_model:
            from scipy.io.wavfile import write
            import numpy as np
            import tempfile
            
            base_speaker_tts = openvoice_model['base_speaker_tts']
            tone_color_converter = openvoice_model['tone_color_converter']
            device = openvoice_model['device']
            
            # Generate base speech
            src_path = 'resources/audio/reference.wav'  # Default reference
            if not os.path.exists(src_path):
                # Use MeloTTS to generate base
                speaker_ids = tts_model.hps.data.spk2id
                speaker_id = speaker_ids.get('EN-US', 0)
                
                speed = 1.0
                output_path = tempfile.mktemp(suffix='.wav')
                tts_model.tts_to_file(text, speaker_id, output_path, speed=speed)
                
                # Clone voice
                tgt_path = tempfile.mktemp(suffix='.wav')
                encode_message = "@MyShell"
                se, audio_name = se_extractor.get_se(src_path, tone_color_converter, vad_model=None)
                
                speaker_src = base_speaker_tts.tts(text, src_path, language=language)
                speaker_tgt = tone_color_converter.convert(
                    audio_src=speaker_src,
                    src_se=se,
                    tgt_se=se,
                    output_path=tgt_path
                )
                
                # Read and return audio
                with open(tgt_path, 'rb') as f:
                    audio_data = f.read()
                
                os.remove(tgt_path)
                os.remove(output_path)
                
                return send_file(
                    io.BytesIO(audio_data),
                    mimetype='audio/wav',
                    as_attachment=False
                )
            else:
                # Use reference voice
                speaker_src = base_speaker_tts.tts(text, src_path, language=language)
                se, audio_name = se_extractor.get_se(src_path, tone_color_converter, vad_model=None)
                
                tgt_path = tempfile.mktemp(suffix='.wav')
                speaker_tgt = tone_color_converter.convert(
                    audio_src=speaker_src,
                    src_se=se,
                    tgt_se=se,
                    output_path=tgt_path
                )
                
                with open(tgt_path, 'rb') as f:
                    audio_data = f.read()
                
                os.remove(tgt_path)
                
                return send_file(
                    io.BytesIO(audio_data),
                    mimetype='audio/wav',
                    as_attachment=False
                )
        else:
            # Fallback: return empty response (Swift will use system TTS)
            return jsonify({'error': 'OpenVoice not available'}), 503
            
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
    print("🌱 Starting Sprout OpenVoice Service on port 6000...")
    app.run(host='0.0.0.0', port=6000, debug=False)

