require 'logger'

module ArchoTomeLogger
  # TODO: put this in config
  LOG_LEVEL = Logger::DEBUG

  def self.logger
    @@logger ||= Logger.new(
      STDOUT,
      level: LOG_LEVEL,
      formatter: proc { |severity, datetime, progname, msg| "[#{severity}] #{msg}\n" }
    )
  end
end

def logger
  ArchoTomeLogger.logger
end
