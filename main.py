#!/usr/bin/env python3
"""Main CLI interface for Sprout voice assistant."""
import sys
import signal
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent))

from src.assistant.conversation_engine import ConversationEngine
from src.utils.logger import logger
from src.utils.config import config
from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.prompt import Prompt

console = Console()

class SproutCLI:
    """Command-line interface for Sprout."""
    
    def __init__(self):
        """Initialize CLI."""
        self.engine = ConversationEngine()
        self.running = True
        
        # Handle signals
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle interrupt signals."""
        console.print("\n[yellow]Shutting down...[/yellow]")
        self.engine.stop_conversation()
        self.running = False
        sys.exit(0)
    
    def display_welcome(self):
        """Display welcome message."""
        welcome_text = Text()
        welcome_text.append("🌱 ", style="green")
        welcome_text.append("Sprout - Mind Wellbeing Voice Assistant", style="bold green")
        welcome_text.append("\n\n", style="white")
        welcome_text.append("I'm here to support your mind wellbeing through voice and conversation.", style="white")
        welcome_text.append("\n", style="white")
        welcome_text.append("Type 'quit' or 'exit' to end the conversation.", style="dim white")
        
        console.print(Panel(welcome_text, border_style="green", title="Welcome"))
    
    def display_response(self, result: dict):
        """Display assistant response with emoji."""
        if "error" in result:
            console.print(f"[red]Error: {result['error']}[/red]")
            return
        
        # Main response
        response_text = Text()
        response_text.append(result.get("emoji", "🌱"), style="green")
        response_text.append(" ", style="white")
        response_text.append(result.get("response", ""), style="white")
        
        console.print(Panel(response_text, border_style="green", title="Sprout"))
        
        # Emotion info
        if result.get("emotion") and result.get("emotion") != "neutral":
            emotion_text = f"Detected emotion: {result['emotion']} (confidence: {result.get('confidence', 0):.2f})"
            console.print(f"[dim]{emotion_text}[/dim]")
        
        # Suggestions
        if result.get("suggestions"):
            console.print("\n[cyan]Suggestions:[/cyan]")
            for i, suggestion in enumerate(result["suggestions"][:3], 1):
                console.print(f"  {i}. {suggestion}")
    
    def run_text_mode(self):
        """Run in text-only mode."""
        self.display_welcome()
        self.engine.start_conversation(voice_enabled=False)
        
        console.print("\n[dim]Enter your message (or 'quit' to exit):[/dim]\n")
        
        while self.running:
            try:
                user_input = Prompt.ask("[bold green]You[/bold green]")
                
                if not user_input or user_input.lower() in ['quit', 'exit', 'q']:
                    break
                
                if user_input.strip():
                    result = self.engine.process_text_input(user_input)
                    self.display_response(result)
                    console.print()  # Empty line for spacing
                    
            except KeyboardInterrupt:
                break
            except Exception as e:
                logger.error(f"Error in text mode: {e}")
                console.print(f"[red]An error occurred: {e}[/red]")
        
        self.engine.stop_conversation()
        console.print("\n[yellow]Thank you for using Sprout. Take care! 🌱[/yellow]")
    
    def run_voice_mode(self):
        """Run in voice mode."""
        self.display_welcome()
        console.print("\n[yellow]Starting voice mode...[/yellow]")
        console.print("[dim]Say 'quit' or press Ctrl+C to exit[/dim]\n")
        
        self.engine.start_conversation(voice_enabled=True)
        
        # Also allow text input for commands
        try:
            while self.running:
                try:
                    user_input = Prompt.ask("[bold green]You[/bold green]", default="")
                    
                    if user_input.lower() in ['quit', 'exit', 'q']:
                        break
                    
                    if user_input.strip():
                        result = self.engine.process_voice_input(user_input)
                        self.display_response(result)
                        console.print()
                        
                except KeyboardInterrupt:
                    break
                except EOFError:
                    break
                    
        except KeyboardInterrupt:
            pass
        
        self.engine.stop_conversation()
        console.print("\n[yellow]Thank you for using Sprout. Take care! 🌱[/yellow]")
    
    def run(self):
        """Run the CLI application."""
        try:
            # Ask for mode
            mode = Prompt.ask(
                "\n[cyan]Choose mode:[/cyan]",
                choices=["text", "voice", "t", "v"],
                default="text"
            )
            
            if mode in ["voice", "v"]:
                self.run_voice_mode()
            else:
                self.run_text_mode()
                
        except Exception as e:
            logger.error(f"Error running CLI: {e}")
            console.print(f"[red]Error: {e}[/red]")
            sys.exit(1)

def main():
    """Main entry point."""
    try:
        cli = SproutCLI()
        cli.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        console.print(f"[red]Fatal error: {e}[/red]")
        sys.exit(1)

if __name__ == "__main__":
    main()

