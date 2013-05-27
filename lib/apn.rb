require "active_support/core_ext"
require "active_support/json"
require 'resque'

module APN
  QUEUE_NAME = :apple_push_notifications
end
require 'apn/notification'
require 'apn/notification_job'
require 'apn/connection'
require 'apn/client'
require 'apn/sender'
require 'apn/feedback'

module APN

  class << self
    include APN::Connection

    # Enqueues a notification to be sent in the background via the persistent TCP socket, assuming apn_sender is running (or will be soon)
    def notify(token, opts = {})
      token = token.to_s.gsub(/\W/, '')
      Resque.enqueue(APN::NotificationJob, token, opts)
    end

    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    # Log message to any logger provided by the user (e.g. the Rails logger).
    # Accepts +log_level+, +message+, since that seems to make the most sense,
    # and just +message+, to be compatible with Resque's log method and to enable
    # sending verbose and very_verbose worker messages to e.g. the rails logger.
    #
    # Perhaps a method definition of +message, +level+ would make more sense, but
    # that's also the complete opposite of what anyone comming from rails would expect.
    alias_method(:resque_log, :log) if defined?(log)
    def log(level, message = nil)
      level, message = 'info', level if message.nil? # Handle only one argument if called from Resque, which expects only message

      resque_log(message) if defined?(resque_log)
      return false unless self.logger && self.logger.respond_to?(level)
      logger.send(level, "#{Time.now}: #{message}")
    end

    # Log the message first, to ensure it reports what went wrong if in daemon mode.
    # Then die, because something went horribly wrong.
    def log_and_die(msg)
      logger.fatal(msg)
      raise msg
    end
  end
end
