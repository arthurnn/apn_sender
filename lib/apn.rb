require "openssl"
require "socket"

require "active_support/core_ext"
require "active_support/json"
require 'connection_pool'

require "apn/version"
require 'apn/connection'

module APN
  QUEUE_NAME = :apple_push_notifications

  class << self
    include APN::Connection

    # Enqueues a notification to be sent in the background via the persistent TCP socket, assuming apn_sender is running (or will be soon)
    def notify_async(token, opts = {})
      token = token.to_s.gsub(/\W/, '')
      if defined?(Resque)
        Resque.enqueue(APN::NotificationJob, token, opts)
      else
        Thread.new do
          APN.notify_sync(token, opts)
        end
      end
    end

    def notify(token, opts = {})
      ## TODO : DEPRECATED
      notify_async(token, opts)
    end

    def notify_sync(token, opts)
      token = token.to_s.gsub(/\W/, '')
      msg = APN::Notification.new(token, opts)
      raise "Invalid notification options (did you provide :alert, :badge, or :sound?): #{opts.inspect}" unless msg.valid?

      APN.with_connection do |client|
        client.push(msg)
      end
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
    def log(level, message = nil)
      level, message = 'info', level if message.nil? # Handle only one argument if called from Resque, which expects only message

      return false unless logger && logger.respond_to?(level)
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


require 'apn/notification'
require 'apn/client'
require 'apn/feedback'

if defined?(Resque)
  require 'apn/notification_job'
end

if defined?(Rails)
  APN.root = File.join(Rails.root, "config", "certs")
  APN.certificate_name = Rails.env.development? ? "apn_development.pem" : "apn_production.pem"
  logger = Logger.new(File.join(Rails.root, 'log', 'apn_sender.log'))
  APN.logger = logger
end
