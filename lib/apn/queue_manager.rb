# Extending Resque to respond to the +before_unregister_worker+ hook. Note this requires a matching
# monkeypatch in the Resque::Worker class. See +resque/hooks/before_unregister_worker.rb+ for an
# example implementation

module APN
  # Extends Resque, allowing us to add all the callbacks to Resque we desire without affecting the expected
  # functionality in the parent app, if we're included in e.g. a Rails application.
  class QueueManager
    extend Resque

    def self.before_unregister_worker(&block)
      block ? (@before_unregister_worker = block) : @before_unregister_worker
    end

    def self.before_unregister_worker=(before_unregister_worker)
      @before_unregister_worker = before_unregister_worker
    end

    def self.to_s
      "APN::QueueManager (Resque Client) connected to #{redis.server}"
    end
  end
  
end

# Ensures we close any open sockets when the worker exits
APN::QueueManager.before_unregister_worker do |worker|
  worker.send(:teardown_connection) if worker.respond_to?(:teardown_connection)
end


# # Run N jobs per fork, rather than creating a new fork for each notification
# # By defunkt - http://gist.github.com/349376
# APN::QueueManager.after_fork do |job|
#   # How many jobs should we process in each fork?
#   jobs_per_fork = 10
# 
#   # Set hook to nil to prevent running this hook over
#   # and over while processing more jobs in this fork.
#   Resque.after_fork = nil
# 
#   # Make sure we process jobs in the right order.
#   job.worker.process(job)
# 
#   # One less than specified because the child will run a
#   # final job after exiting this hook.
#   (jobs_per_fork.to_i - 1).times do
#     job.worker.process
#   end
# end

