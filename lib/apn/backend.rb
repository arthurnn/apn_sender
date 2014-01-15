module APN
  module Backend
    autoload :Sidekiq,     'apn/backend/sidekiq'
    autoload :Resque,      'apn/backend/resque'

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
