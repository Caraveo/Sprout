# Enabling Remote Access for Ollama

To use Ollama from other devices on your network (remote access), you need to configure Ollama to listen on all network interfaces.

## macOS

1. **Set environment variable:**
   ```bash
   export OLLAMA_HOST=0.0.0.0:11434
   ```

2. **Or create/edit `~/.ollama/ollama.env`:**
   ```bash
   mkdir -p ~/.ollama
   echo "OLLAMA_HOST=0.0.0.0:11434" >> ~/.ollama/ollama.env
   ```

3. **Restart Ollama:**
   ```bash
   ollama serve
   ```

4. **Find your IP address:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Or check System Settings > Network

5. **In Sprout Settings:**
   - Enable "Allow Remote Access" toggle
   - Set Base URL to: `http://YOUR_IP_ADDRESS:11434`
   - Example: `http://192.168.1.100:11434`

## Security Note

⚠️ **Warning:** Enabling remote access makes Ollama accessible to anyone on your network. Only enable this on trusted networks (home/office). For production, use proper authentication and firewall rules.

## Testing Remote Access

1. Open Sprout Settings
2. Enable "Allow Remote Access"
3. Set Base URL to your computer's IP address
4. Click "Refresh Models" to fetch available models
5. Click "Test Connection" to verify connectivity

## Troubleshooting

- **Can't connect:** Make sure Ollama is running with `OLLAMA_HOST=0.0.0.0:11434`
- **Firewall blocking:** Check macOS Firewall settings
- **Wrong IP:** Use `ifconfig` or System Settings to find your local IP address
- **Models not showing:** Click "Refresh Models" after connecting successfully

