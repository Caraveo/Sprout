"""Flask web application for Sprout voice assistant."""
from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import os
from pathlib import Path

from src.assistant.conversation_engine import ConversationEngine
from src.utils.logger import logger
from src.utils.config import config

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Initialize conversation engine
engine = ConversationEngine()

@app.route('/')
def index():
    """Serve main page."""
    return render_template('index.html')

@app.route('/api/chat', methods=['POST'])
def chat():
    """Handle text chat requests."""
    try:
        data = request.json
        user_input = data.get('message', '').strip()
        
        if not user_input:
            return jsonify({'error': 'No message provided'}), 400
        
        # Process input
        result = engine.process_text_input(user_input)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/start', methods=['POST'])
def start_conversation():
    """Start a conversation session."""
    try:
        data = request.json or {}
        voice_enabled = data.get('voice_enabled', False)
        
        engine.start_conversation(voice_enabled=voice_enabled)
        
        return jsonify({
            'status': 'started',
            'message': 'Conversation started'
        })
        
    except Exception as e:
        logger.error(f"Error starting conversation: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/stop', methods=['POST'])
def stop_conversation():
    """Stop the conversation session."""
    try:
        engine.stop_conversation()
        
        return jsonify({
            'status': 'stopped',
            'message': 'Conversation stopped'
        })
        
    except Exception as e:
        logger.error(f"Error stopping conversation: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/summary', methods=['GET'])
def get_summary():
    """Get conversation summary."""
    try:
        summary = engine.get_conversation_summary()
        return jsonify(summary)
        
    except Exception as e:
        logger.error(f"Error getting summary: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/reset', methods=['POST'])
def reset_conversation():
    """Reset conversation history."""
    try:
        engine.reset_conversation()
        return jsonify({'status': 'reset', 'message': 'Conversation reset'})
        
    except Exception as e:
        logger.error(f"Error resetting conversation: {e}")
        return jsonify({'error': str(e)}), 500

@socketio.on('connect')
def handle_connect():
    """Handle client connection."""
    logger.info('Client connected')
    emit('connected', {'message': 'Connected to Sprout'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection."""
    logger.info('Client disconnected')

@socketio.on('message')
def handle_message(data):
    """Handle WebSocket messages."""
    try:
        user_input = data.get('message', '').strip()
        
        if not user_input:
            emit('error', {'message': 'No message provided'})
            return
        
        # Process input
        result = engine.process_text_input(user_input)
        
        # Emit response
        emit('response', result)
        
    except Exception as e:
        logger.error(f"Error handling WebSocket message: {e}")
        emit('error', {'message': str(e)})

if __name__ == '__main__':
    # Ensure templates directory exists
    templates_dir = Path(__file__).parent / 'templates'
    templates_dir.mkdir(exist_ok=True)
    
    # Create basic HTML template if it doesn't exist
    template_file = templates_dir / 'index.html'
    if not template_file.exists():
        _create_default_template(template_file)
    
    logger.info("Starting Sprout web application...")
    socketio.run(app, host='0.0.0.0', port=5000, debug=False)

def _create_default_template(template_path: Path):
    """Create a default HTML template."""
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sprout - Mind Wellbeing Assistant</title>
    <script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 600px;
            height: 80vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2em;
            margin-bottom: 5px;
        }
        
        .header p {
            opacity: 0.9;
        }
        
        .chat-area {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
            background: #f5f5f5;
        }
        
        .message {
            margin-bottom: 15px;
            display: flex;
            align-items: flex-start;
        }
        
        .message.user {
            justify-content: flex-end;
        }
        
        .message-content {
            max-width: 70%;
            padding: 12px 16px;
            border-radius: 18px;
            word-wrap: break-word;
        }
        
        .message.user .message-content {
            background: #667eea;
            color: white;
        }
        
        .message.assistant .message-content {
            background: white;
            color: #333;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        
        .emoji {
            font-size: 1.5em;
            margin-right: 8px;
        }
        
        .input-area {
            padding: 20px;
            background: white;
            border-top: 1px solid #e0e0e0;
        }
        
        .input-container {
            display: flex;
            gap: 10px;
        }
        
        input[type="text"] {
            flex: 1;
            padding: 12px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 25px;
            font-size: 16px;
            outline: none;
            transition: border-color 0.3s;
        }
        
        input[type="text"]:focus {
            border-color: #667eea;
        }
        
        button {
            padding: 12px 24px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.3s;
        }
        
        button:hover {
            background: #5568d3;
        }
        
        button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        
        .suggestions {
            margin-top: 10px;
            padding: 10px;
            background: #f0f0f0;
            border-radius: 10px;
            font-size: 0.9em;
        }
        
        .suggestions-title {
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .suggestion-item {
            margin: 5px 0;
            padding-left: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌱 Sprout</h1>
            <p>Mind Wellbeing Voice Assistant</p>
        </div>
        
        <div class="chat-area" id="chatArea">
            <div class="message assistant">
                <div class="message-content">
                    <span class="emoji">🌱</span>
                    Hello! I'm Sprout, and I'm here to support your mind wellbeing. How can I help you today?
                </div>
            </div>
        </div>
        
        <div class="input-area">
            <div class="input-container">
                <input type="text" id="messageInput" placeholder="Type your message..." autocomplete="off">
                <button id="sendButton" onclick="sendMessage()">Send</button>
            </div>
        </div>
    </div>
    
    <script>
        const socket = io();
        const chatArea = document.getElementById('chatArea');
        const messageInput = document.getElementById('messageInput');
        const sendButton = document.getElementById('sendButton');
        
        socket.on('connect', () => {
            console.log('Connected to Sprout');
        });
        
        socket.on('response', (data) => {
            addMessage('assistant', data.formatted_response || data.response, data.emoji, data.suggestions);
        });
        
        socket.on('error', (data) => {
            addMessage('assistant', 'Error: ' + data.message, '⚠️');
        });
        
        messageInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
        
        function sendMessage() {
            const message = messageInput.value.trim();
            if (!message) return;
            
            addMessage('user', message);
            messageInput.value = '';
            sendButton.disabled = true;
            
            // Send via WebSocket
            socket.emit('message', { message: message });
            
            // Also try REST API as fallback
            fetch('/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: message })
            })
            .then(response => response.json())
            .then(data => {
                if (data.error) {
                    addMessage('assistant', 'Error: ' + data.error, '⚠️');
                } else {
                    addMessage('assistant', data.formatted_response || data.response, data.emoji, data.suggestions);
                }
                sendButton.disabled = false;
            })
            .catch(error => {
                console.error('Error:', error);
                sendButton.disabled = false;
            });
        }
        
        function addMessage(type, text, emoji = null, suggestions = null) {
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${type}`;
            
            const contentDiv = document.createElement('div');
            contentDiv.className = 'message-content';
            
            if (emoji && type === 'assistant') {
                const emojiSpan = document.createElement('span');
                emojiSpan.className = 'emoji';
                emojiSpan.textContent = emoji;
                contentDiv.appendChild(emojiSpan);
            }
            
            const textSpan = document.createElement('span');
            textSpan.textContent = text;
            contentDiv.appendChild(textSpan);
            
            if (suggestions && suggestions.length > 0) {
                const suggestionsDiv = document.createElement('div');
                suggestionsDiv.className = 'suggestions';
                suggestionsDiv.innerHTML = '<div class="suggestions-title">Suggestions:</div>';
                suggestions.forEach(suggestion => {
                    const item = document.createElement('div');
                    item.className = 'suggestion-item';
                    item.textContent = '• ' + suggestion;
                    suggestionsDiv.appendChild(item);
                });
                contentDiv.appendChild(suggestionsDiv);
            }
            
            messageDiv.appendChild(contentDiv);
            chatArea.appendChild(messageDiv);
            chatArea.scrollTop = chatArea.scrollHeight;
        }
    </script>
</body>
</html>"""
    
    template_path.write_text(html_content)
    logger.info(f"Created default template at {template_path}")

