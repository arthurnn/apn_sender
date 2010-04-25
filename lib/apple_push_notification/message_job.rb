module ApplePushNotification
  # This is the class that's actually enqueued via Resque when user calls +ApplePushNotification.send_message+.
  # It gets added to the +apple_server_notifications+ Resque queue, which should only be operated on by
  # workers of the +ApplePushNotification::Sender+ class.
  class MessageJob
    # Behind the scenes, this is the name of our Resque queue
    @queue = ApplePushNotification::QUEUE_NAME
    
    # Build a message from arguments and send to Apple
    def self.perform(token, message_options)
      msg = ApplePushNotification::Message.new(token, message_options)
      raise "Invalid message options: #{message_options.inspect}" unless msg.valid?
      worker.send_to_apple( msg )
    end
   
   
    # Only execute this job in specialized ApplePushNotification::Sender workers, since
    # standard Resque workers don't maintain the persistent TCP connection.
    extend Resque::Plugins::AccessWorkerFromJob
    self.required_worker_class = 'ApplePushNotification::Sender'
  end
end