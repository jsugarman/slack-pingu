require 'logger'

module AppLogger
  def self.logger_instance
    @logger ||= Logger.new(STDOUT)
  end

  def self.included(base)
    def logger
      AppLogger.logger_instance
    end
  end
end
