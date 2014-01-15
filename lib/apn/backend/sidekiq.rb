begin
  require 'sidekiq'
  require 'apn/jobs/sidekiq_notification_job'
rescue LoadError => e
  $stderr.puts "You don't have sidekiq installed in your application. Please add it to your Gemfile and run bundle install"
  raise e
end

module APN
  module Backend
    class Sidekiq
      def notify(token, opts)
        ::Sidekiq::Client.enqueue(APN::Jobs::SidekiqNotificationJob, token, opts)
      end
    end
  end
end
