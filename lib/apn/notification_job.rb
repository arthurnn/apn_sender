module APN
  # This is the class that's actually enqueued via Resque when user calls +APN.notify+.
  # It gets added to the +apple_server_notifications+ Resque queue, which should only be operated on by
  # workers of the +APN::Sender+ class.
  class NotificationJob
    # Behind the scenes, this is the name of our Resque queue
    @queue = APN::QUEUE_NAME

    # Build a notification from arguments and send to Apple
    def self.perform(token, opts)
      APN.notify_sync(token, opts)
    end
  end
end
