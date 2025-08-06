require "time"

class CommandHandler
  @config : Config
  @logger : BotLogger
  @start_time : Time
  @commands : Hash(String, Proc(String, String, String, String?))

  def initialize(@config : Config, @logger : BotLogger)
    @start_time = Time.utc
    @commands = Hash(String, Proc(String, String, String, String?)).new
    setup_default_commands
  end

  def handle_command(username : String, channel : String, message : String) : String?
    return nil unless message.starts_with?(@config.command_prefix)
    
    # Remove prefix and split into command and arguments
    command_text = message[@config.command_prefix.size..]
    parts = command_text.split(' ', 2)
    command = parts[0].downcase
    args = parts.size > 1 ? parts[1] : ""
    
    @logger.info("Command from #{username} in #{channel}: #{command} #{args}")
    
    if handler = @commands[command]?
      begin
        response = handler.call(username, channel, args)
        @logger.info("Command response: #{response}") if response
        return response
      rescue ex : Exception
        @logger.error("Error handling command #{command}: #{ex.message}")
        return "Sorry, there was an error processing that command."
      end
    else
      @logger.debug("Unknown command: #{command}")
      return nil
    end
  end

  def add_command(name : String, &handler : String, String, String -> String?)
    @commands[name] = handler
    @logger.info("Added command: #{name}")
  end

  def remove_command(name : String)
    @commands.delete(name)
    @logger.info("Removed command: #{name}")
  end

  private def setup_default_commands
    # Hello command
    add_command("hello") do |username, channel, args|
      "Hello #{username}! 👋"
    end

    # Uptime command
    add_command("uptime") do |username, channel, args|
      uptime = Time.utc - @start_time
      hours = (uptime.total_seconds / 3600).floor.to_i
      minutes = ((uptime.total_seconds % 3600) / 60).floor.to_i
      seconds = (uptime.total_seconds % 60).floor.to_i
      
      if hours > 0
        "Bot uptime: #{hours}h #{minutes}m #{seconds}s"
      elsif minutes > 0
        "Bot uptime: #{minutes}m #{seconds}s"
      else
        "Bot uptime: #{seconds}s"
      end
    end

    # Time command
    add_command("time") do |username, channel, args|
      "Current time (UTC): #{Time.utc.to_s("%Y-%m-%d %H:%M:%S")}"
    end

    # Help command
    add_command("help") do |username, channel, args|
      available_commands = @commands.keys.sort.join(", ")
      "Available commands: #{available_commands}"
    end

    # Commands command (alias for help)
    add_command("commands") do |username, channel, args|
      available_commands = @commands.keys.sort.join(", ")
      "Available commands: #{available_commands}"
    end

    # Bot info command
    add_command("botinfo") do |username, channel, args|
      "TwitchBot v0.1.0 - Built with Crystal 💎"
    end

    # Echo command (for testing)
    add_command("echo") do |username, channel, args|
      if args.empty?
        "Usage: !echo <message>"
      else
        "#{username} said: #{args}"
      end
    end

    # Roll dice command
    add_command("roll") do |username, channel, args|
      if args.empty?
        sides = 6
      else
        begin
          sides = args.to_i
          if sides < 2 || sides > 1000
            next "Dice must have between 2 and 1000 sides."
          end
        rescue
          next "Invalid number of sides. Usage: !roll [sides]"
        end
      end
      
      result = Random.rand(1..sides)
      "🎲 #{username} rolled a #{result} (1-#{sides})"
    end

    @logger.info("Default commands setup complete")
  end
end
