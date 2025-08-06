# Twitch Chat Bot (Crystal)

A Twitch chat bot built in Crystal language with IRC connectivity and command handling.

## Features

- **IRC Connectivity**: Connects to Twitch IRC servers using TCP sockets
- **Command System**: Extensible command handling with built-in commands
- **Moderation**: Basic spam and caps detection
- **Auto-Reconnect**: Automatic reconnection on network issues
- **Logging**: Configurable logging levels for debugging and monitoring
- **Configuration**: YAML configuration with environment variable overrides

## Built-in Commands

- `!hello` - Greet the user
- `!uptime` - Show bot uptime
- `!time` - Show current UTC time
- `!help` / `!commands` - List available commands
- `!botinfo` - Show bot information
- `!echo <message>` - Echo back a message
- `!roll [sides]` - Roll a dice (default 6 sides)

## Setup

### 1. Get a Twitch OAuth Token

1. Visit [https://twitchapps.com/tmi/](https://twitchapps.com/tmi/)
2. Click "Connect with Twitch"
3. Copy the OAuth token (it will start with `oauth:`)

### 2. Configure the Bot

**Recommended method (using environment variables):**

```bash
export TWITCH_OAUTH_TOKEN="oauth:your_token_here"
export TWITCH_NICKNAME="your_bot_name"
export TWITCH_CHANNELS="#your_channel,#another_channel"
```

**Alternative method (edit config.yml):**

```yaml
oauth_token: "oauth:your_token_here"
nickname: "your_bot_name"
channels:
  - "#your_channel"
command_prefix: "!"
log_level: "info"
