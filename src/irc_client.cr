require "socket"

class IRCClient
  @socket : TCPSocket?
  @config : Config
  @logger : BotLogger
  @connected : Bool = false

  def initialize(@config : Config, @logger : BotLogger)
  end

  def connect
    @logger.info("Connecting to #{@config.irc_server}:#{@config.irc_port}")
    
    @socket = TCPSocket.new(@config.irc_server, @config.irc_port)
    @socket.not_nil!.read_timeout = @config.timeout.seconds
    @socket.not_nil!.write_timeout = 10.seconds
    
    @connected = true
    @logger.info("Connected to Twitch IRC")
  end

  def disconnect
    if @socket
      @socket.not_nil!.close
      @socket = nil
    end
    @connected = false
    @logger.info("Disconnected from Twitch IRC")
  end

  def authenticate(oauth_token : String, nickname : String)
    raise "Not connected" unless @connected && @socket
    
    @logger.info("Authenticating as #{nickname}")
    
    # Send CAP REQ for Twitch-specific capabilities
    send_raw("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
    
    # Send PASS (OAuth token)
    send_raw("PASS #{oauth_token}")
    
    # Send NICK
    send_raw("NICK #{nickname}")
    
    # Wait for authentication response
    timeout = Time.utc + 10.seconds
    while Time.utc < timeout
      response = read_message
      next if response.nil? || response.empty?
      
      @logger.debug("Auth response: #{response}")
      
      if response.includes?("Welcome") || response.includes?("001")
        @logger.info("Authentication successful")
        return
      elsif response.includes?("Login authentication failed") || response.includes?("NOTICE")
        raise "Authentication failed: #{response}"
      end
    end
    
    raise "Authentication timeout"
  end

  def join_channel(channel : String)
    raise "Not connected" unless @connected && @socket
    
    @logger.info("Joining channel: #{channel}")
    send_raw("JOIN #{channel}")
  end

  def leave_channel(channel : String)
    raise "Not connected" unless @connected && @socket
    
    @logger.info("Leaving channel: #{channel}")
    send_raw("PART #{channel}")
  end

  def send_message(channel : String, message : String)
    raise "Not connected" unless @connected && @socket
    
    # Split long messages
    max_length = 450  # Leave room for IRC overhead
    if message.size > max_length
      message = message[0, max_length] + "..."
    end
    
    privmsg = "PRIVMSG #{channel} :#{message}"
    send_raw(privmsg)
    @logger.info("Sent to #{channel}: #{message}")
  end

  def send_raw(message : String)
    raise "Not connected" unless @connected && @socket
    
    formatted_message = "#{message}\r\n"
    @socket.not_nil!.write(formatted_message.to_slice)
    @socket.not_nil!.flush
    @logger.debug("Sent raw: #{message}")
  end

  def read_message : String?
    return nil unless @connected && @socket
    
    begin
      line = @socket.not_nil!.gets
      return line.try(&.chomp) if line
    rescue IO::TimeoutError
      # Timeout is expected for non-blocking reads
      return nil
    rescue ex : Exception
      @logger.error("Error reading message: #{ex.message}")
      @connected = false
      raise ex
    end
    
    nil
  end

  def connected? : Bool
    @connected && @socket && !@socket.not_nil!.closed?
  end
end
