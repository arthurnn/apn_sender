module APN
  module Backend

    class Sidekiq

      def notify(token, opts)
        ::Sidekiq::Client.enqueue(APN::Jobs::SidekiqNotificationJob, token, opts)
      end
    end

    class Resque

      def notify(token, opts)
        ::Resque.enqueue(APN::Jobs::ResqueNotificationJob, token, opts)
      end
    end

    class Simple

      def notify(token, opts)
        Thread.new do
          APN.notify_sync(token, opts)
        end
      end
    end

    class Null

      def notify(token, opts)
        APN.log("Null Backend sending message to #{token}")
      end
    end
  end
end
