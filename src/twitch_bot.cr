require "./config"
require "./irc_client"
require "./command_handler"
require "./logger"

class TwitchBot
  @config : Config
  @irc_client : IRCClient
  @command_handler : CommandHandler
  @logger : BotLogger
  @running : Bool = false

  def initialize(config_path : String = "config.yml")
    @config = Config.load(config_path)
    @logger = BotLogger.new(@config.log_level)
    @irc_client = IRCClient.new(@config, @logger)
    @command_handler = CommandHandler.new(@config, @logger)
    
    @logger.info("TwitchBot initialized")
  end

  def start
    @logger.info("Starting Twitch bot...")
    @running = true
    
    setup_signal_handlers
    
    begin
      @irc_client.connect
      @irc_client.authenticate(@config.oauth_token, @config.nickname)
      
      @config.channels.each do |channel|
        @irc_client.join_channel(channel)
        @logger.info("Joined channel: #{channel}")
      end
      
      start_message_loop
    rescue ex : Exception
      @logger.error("Failed to start bot: #{ex.message}")
      raise ex
    end
  end

  def stop
    @logger.info("Stopping Twitch bot...")
    @running = false
    @irc_client.disconnect
    @logger.info("Bot stopped")
  end

  private def setup_signal_handlers
    Signal::INT.trap do
      @logger.info("Received SIGINT, shutting down...")
      stop
      exit(0)
    end

    Signal::TERM.trap do
      @logger.info("Received SIGTERM, shutting down...")
      stop
      exit(0)
    end
  end

  private def start_message_loop
    @logger.info("Starting message loop...")
    
    while @running
      begin
        message = @irc_client.read_message
        next if message.nil? || message.empty?
        
        @logger.debug("Received: #{message}")
        
        if message.includes?("PING")
          handle_ping(message)
        elsif message.includes?("PRIVMSG")
          handle_privmsg(message)
        elsif message.includes?("JOIN") || message.includes?("PART")
          handle_user_event(message)
        end
        
      rescue ex : IO::TimeoutError
        # Timeout is expected, continue loop
        next
      rescue ex : Exception
        @logger.error("Error in message loop: #{ex.message}")
        
        # Attempt to reconnect
        if should_reconnect?
          @logger.info("Attempting to reconnect...")
          reconnect
        else
          break
        end
      end
    end
  end

  private def handle_ping(message : String)
    if match = message.match(/PING :(.+)/)
      pong_response = "PONG :#{match[1]}"
      @irc_client.send_raw(pong_response)
      @logger.debug("Responded to PING with PONG")
    end
  end

  private def handle_privmsg(message : String)
    # Parse PRIVMSG format: :username!username@username.tmi.twitch.tv PRIVMSG #channel :message
    if match = message.match(/:(\w+)!\w+@\w+\.tmi\.twitch\.tv PRIVMSG (#\w+) :(.+)/)
      username = match[1]
      channel = match[2]
      content = match[3]
      
      @logger.info("[#{channel}] #{username}: #{content}")
      
      # Handle commands
      if content.starts_with?(@config.command_prefix)
        command_response = @command_handler.handle_command(username, channel, content)
        if command_response
          @irc_client.send_message(channel, command_response)
        end
      end
      
      # Handle moderation
      handle_moderation(username, channel, content)
    end
  end

  private def handle_user_event(message : String)
    @logger.debug("User event: #{message}")
  end

  private def handle_moderation(username : String, channel : String, message : String)
    # Basic spam detection
    if message.size > @config.max_message_length
      @logger.warn("Long message from #{username} in #{channel}: #{message.size} characters")
      # Could implement timeout here
    end
    
    # Basic caps detection
    if message.upcase == message && message.size > 10
      @logger.warn("All caps message from #{username} in #{channel}")
      # Could implement warning here
    end
  end

  private def should_reconnect? : Bool
    @running && @config.auto_reconnect
  end

  private def reconnect
    begin
      @irc_client.disconnect
      sleep(@config.reconnect_delay.seconds)
      @irc_client.connect
      @irc_client.authenticate(@config.oauth_token, @config.nickname)
      
      @config.channels.each do |channel|
        @irc_client.join_channel(channel)
      end
      
      @logger.info("Reconnected successfully")
    rescue ex : Exception
      @logger.error("Reconnection failed: #{ex.message}")
    end
  end
end

# Main execution
if ARGV.size > 0 && ARGV[0] == "--help"
  puts "Twitch Bot Usage:"
  puts "  crystal run src/twitch_bot.cr [config_file]"
  puts ""
  puts "Options:"
  puts "  config_file    Path to configuration file (default: config.yml)"
  puts "  --help         Show this help message"
  exit(0)
end

config_file = ARGV.size > 0 ? ARGV[0] : "config.yml"

begin
  bot = TwitchBot.new(config_file)
  bot.start
rescue ex : Exception
  puts "Error: #{ex.message}"
  exit(1)
end
