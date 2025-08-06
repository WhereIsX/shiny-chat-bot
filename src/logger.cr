require "log"

class BotLogger
  @logger : Log

  def initialize(level : String = "info")
    Log.setup_from_env(default_level: parse_level(level))
    @logger = Log.for("TwitchBot")
  end

  def debug(message : String)
    @logger.debug { message }
  end

  def info(message : String)
    @logger.info { message }
  end

  def warn(message : String)
    @logger.warn { message }
  end

  def error(message : String)
    @logger.error { message }
  end

  def fatal(message : String)
    @logger.fatal { message }
  end

  private def parse_level(level : String) : Log::Severity
    case level.downcase
    when "debug"
      Log::Severity::Debug
    when "info"
      Log::Severity::Info
    when "warn", "warning"
      Log::Severity::Warn
    when "error"
      Log::Severity::Error
    when "fatal"
      Log::Severity::Fatal
    else
      Log::Severity::Info
    end
  end
end
