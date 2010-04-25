require 'resque'
require 'resque/plugins/access_worker_from_job'
require 'resque/hooks/before_unregister_worker'

begin
  require 'yajl/json_gem'
rescue LoadError
  require 'json'
end

require 'apn/queue_manager'

module APN
  # Change this to modify the queue notification jobs are pushed to and pulled from
  QUEUE_NAME = :apple_push_notifications
  
  # Enqueues a notification to be sent in the background via the persistent TCP socket, assuming apn_sender is running (or will be soon)
  def self.notify(token, opts = {})
    APN::QueueManager.enqueue(APN::NotificationJob, token, opts)
  end  
end

require 'apn/notification'
require 'apn/notification_job'
require 'apn/sender'