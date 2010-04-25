$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'resque'
require 'resque/plugins/access_worker_from_job'
require 'resque/hooks/before_unregister_worker'

begin
  require 'yajl/json_gem'
rescue LoadError
  require 'json'
end

require 'apple_push_notification/queue_manager'

module ApplePushNotification
  # Change this to modify the queue message jobs are pushed to and pulled from
  QUEUE_NAME = :apple_push_notifications
  
  # Enqueues a message to be sent in the background via the persistent TCP socket, assuming apn_sender is running (or will be soon)
  def self.send_message(token, opts = {})
    ApplePushNotification::QueueManager.enqueue(ApplePushNotification::MessageJob, token, opts)
  end  
end

require 'apple_push_notification/message'
require 'apple_push_notification/message_job'
require 'apple_push_notification/sender'
