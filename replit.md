# Overview

A Twitch chat bot built in Crystal language that connects to Twitch IRC servers and provides command handling, moderation features, and automated responses. The bot is designed to be extensible with a plugin-based command system and includes basic moderation capabilities like spam and caps detection.

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Core Components

**IRC Client Architecture**: The bot uses TCP socket connections to communicate with Twitch's IRC servers, implementing the IRC protocol for real-time chat interaction. This approach provides direct, low-level control over the connection and message handling.

**Command System**: Implements an extensible command handler that processes messages starting with a configurable prefix (default "!"). Commands are modular and can be easily added or modified without changing core bot logic.

**Event-Driven Processing**: Uses an event loop to handle incoming IRC messages, parsing them for commands, moderation triggers, and other bot interactions. This ensures responsive real-time chat participation.

**Configuration Management**: Uses YAML-based configuration with environment variable overrides, allowing flexible deployment across different environments while keeping sensitive data separate.

**Logging System**: Implements configurable logging levels for debugging, monitoring, and operational visibility.

**Auto-Reconnection**: Includes network resilience with automatic reconnection logic to handle temporary disconnections from Twitch IRC servers.

## Design Patterns

**Modular Command Architecture**: Commands are designed as separate modules that can be enabled/disabled and extended without modifying core functionality.

**Configuration-Driven Behavior**: Bot behavior is controlled through configuration files rather than hard-coded values, enabling easy customization for different channels and use cases.

# External Dependencies

**Twitch IRC Servers**: Connects to irc.chat.twitch.tv on port 6667 for real-time chat communication.

**Twitch OAuth System**: Requires OAuth tokens from Twitch for authentication, obtained through Twitch's developer portal.

**Crystal Language Runtime**: Built using Crystal language, requiring the Crystal compiler and runtime environment.

**YAML Configuration**: Uses YAML for configuration file parsing and management.