module APN
  # Subclass of Resque::Worker which initializes a single TCP socket on creation to communicate with Apple's Push Notification servers.
  # Shares this socket with each child process forked off by Resque to complete a job. Socket is closed in the before_unregister_worker
  # callback, which gets called on normal or exceptional exits.
  #
  # End result: single persistent TCP connection to Apple, so they don't ban you for frequently opening and closing connections,
  # which they apparently view as a DOS attack.
  #
  # Accepts <code>:environment</code> (production vs anything else) and <code>:cert_path</code> options on initialization.  If called in a 
  # Rails context, will default to RAILS_ENV and RAILS_ROOT/config/certs. :environment will default to development.  
  # APN::Sender expects two files to exist in the specified <code>:cert_path</code> directory: 
  # <code>apn_production.pem</code> and <code>apn_development.pem</code>.
  #
  # If a socket error is encountered, will teardown the connection and retry again twice before admitting defeat.
  class Sender < ::Resque::Worker
    include APN::Connection::Base
    TIMES_TO_RETRY_SOCKET_ERROR = 2
                                
    # Send a raw string over the socket to Apple's servers (presumably already formatted by APN::Notification)
    def send_to_apple( notification, attempt = 0 )
      if attempt > TIMES_TO_RETRY_SOCKET_ERROR
        raise "Error with connection to #{apn_host} (retried #{TIMES_TO_RETRY_SOCKET_ERROR} times): #{error}"
      end
      
      self.socket.write( notification.to_s )
    rescue SocketError => error
      log(:error, "Error with connection to #{apn_host} (attempt #{attempt}): #{error}")
      
      # Try reestablishing the connection
      teardown_connection
      setup_connection
      send_to_apple(notification, attempt + 1)
    end
    
    protected
    
    def apn_host
      @apn_host ||= apn_production? ? "gateway.push.apple.com" : "gateway.sandbox.push.apple.com"
    end
    
    def apn_port
      2195
    end

  end

end


__END__

# irb -r 'lib/apple_push_notification'

## To enqueue test job
k = 'ceecdc18 ef17b2d0 745475e0 0a6cd5bf 54534184 ac2649eb 40873c81 ae76dbe8'
c = '0f58e3e2 77237b8f f8213851 c835dee0 376b7a31 9e0484f7 06fe3035 7c5dda2f'
APN.notify k, 'Resque Test'

# If you need to really force quit some screwed up workers
Resque.workers.map{|w| Resque.redis.srem(:workers, w)}

# To run worker from rake task
CERT_PATH=/Users/kali/Code/insurrection/certs/ ENVIRONMENT=production rake apn:work

# To run worker from IRB 
Resque.workers.map(&:unregister_worker)
require 'ruby-debug'
worker = APN::Sender.new(:cert_path => '/Users/kali/Code/insurrection/certs/', :environment => :production)
worker.very_verbose = true
worker.work(5)

# To run worker as daemon
args = ['--environment=production', '--cert-path=/Users/kali/Code/insurrection/certs/']
APN::SenderDaemon.new(args).daemonize


