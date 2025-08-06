require "yaml"

class Config
  include YAML::Serializable

  property oauth_token : String = ""
  property nickname : String = ""
  property channels : Array(String) = [] of String
  property command_prefix : String = "!"
  property log_level : String = "info"
  property auto_reconnect : Bool = true
  property reconnect_delay : Int32 = 5
  property max_message_length : Int32 = 500
  property irc_server : String = "irc.chat.twitch.tv"
  property irc_port : Int32 = 6667
  property timeout : Int32 = 300

  def initialize
  end

  def self.load(path : String) : Config
    if File.exists?(path)
      config = Config.from_yaml(File.read(path))
    else
      config = Config.new
    end
    
    # Override with environment variables if present
    config.oauth_token = ENV.fetch("TWITCH_OAUTH_TOKEN", config.oauth_token)
    config.nickname = ENV.fetch("TWITCH_NICKNAME", config.nickname)
    
    if channels_env = ENV["TWITCH_CHANNELS"]?
      config.channels = channels_env.split(",").map(&.strip)
    end
    
    # Validate required fields
    validate_config(config)
    
    config
  end

  private def self.validate_config(config : Config)
    errors = [] of String
    
    if config.oauth_token.empty?
      errors << "oauth_token is required (set TWITCH_OAUTH_TOKEN environment variable or config file)"
    end
    
    if config.nickname.empty?
      errors << "nickname is required (set TWITCH_NICKNAME environment variable or config file)"
    end
    
    if config.channels.empty?
      errors << "at least one channel is required (set TWITCH_CHANNELS environment variable or config file)"
    end
    
    unless config.oauth_token.starts_with?("oauth:")
      errors << "oauth_token must start with 'oauth:'"
    end
    
    config.channels.each do |channel|
      unless channel.starts_with?("#")
        errors << "channel names must start with '#': #{channel}"
      end
    end
    
    if errors.any?
      raise "Configuration errors:\n#{errors.join("\n")}"
    end
  end

  def save(path : String)
    File.write(path, to_yaml)
  end
end
