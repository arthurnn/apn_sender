require 'socket'
require 'openssl'
require 'resque'

module ApplePushNotification
  # Subclass of Resque::Worker which initializes a single TCP socket on creation to communicate with Apple's Push Notification servers.
  # Shares this socket with each child process forked off by Resque to complete a job. Socket is closed in the before_unregister_worker
  # callback, which gets called on normal or exceptional exits.
  #
  # End result: single persistent TCP connection to Apple, so they don't ban you for frequently opening and closing connections,
  # which they apparently view as "spammy".
  #
  # Accepts :environment (production vs anything else) and :cert_path options on initialization.  If called in a Rails context 
  # will default to RAILS_ENV and RAILS_ROOT/config/certs. :environment will default to development.  ApplePushNotification::Sender
  # expects two files to exist in the specified :cert_path directory: apn_production.pem and apn_development.pem.
  class Sender < ::Resque::Worker
    APN_PORT = 2195
    attr_accessor :apn_cert, :apn_host, :socket, :socket_tcp, :opts
    
    class << self
      attr_accessor :logger
    end
    
    self.logger = if defined?(Merb::Logger)
      Merb.logger
    elsif defined?(RAILS_DEFAULT_LOGGER)
      RAILS_DEFAULT_LOGGER
    end
    
    def initialize(opts = {})
      @opts = opts
      
      # Set option defaults
      @opts[:cert_path] ||= File.join(File.expand_path(RAILS_ROOT), "config", "certs") if defined?(RAILS_ROOT)
      @opts[:environment] ||= RAILS_ENV if defined?(RAILS_ENV)
      
      logger.info "ApplePushNotification::Sender initializing. Establishing connections first..." if @opts[:verbose]
      setup_paths
      setup_connection
      
      super( ApplePushNotification::QUEUE_NAME )
    end
        
    # Send a raw string over the socket to Apple's servers (presumably already formatted by ApplePushNotification::Message)
    def send_to_apple(msg)
      @socket.write( msg )
    rescue SocketError => error
      logger.error("Error with connection to #{@apn_host}: #{error}")
      raise "Error with connection to #{@apn_host}: #{error}"
    end
            
    protected
    
    def apn_production?
      @opts[:environment] && @opts[:environment] != '' && :production == @opts[:environment].to_sym
    end
    
    # Get a fix on the .pem certificate we'll be using for SSL
    def setup_paths
      raise "Missing certificate path. Please specify :cert_path when initializing class." unless @opts[:cert_path]
      @apn_host = apn_production? ? "gateway.push.apple.com" : "gateway.sandbox.push.apple.com"
      cert_name = apn_production? ? "apn_production.pem" : "apn_development.pem"
      cert_path = File.join(@opts[:cert_path], cert_name)

      @apn_cert = File.exists?(cert_name) ? File.read(cert_name) : nil
      raise "Missing apple push notification certificate in #{cert_path}" unless @apn_cert
    end

    # Open socket to Apple's servers
    def setup_connection
      raise "Missing apple push notification certificate" unless @apn_cert
      raise "Trying to open already-open socket" if @socket || @socket_tcp
      
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.key = OpenSSL::PKey::RSA.new(@apn_cert)
      ctx.cert = OpenSSL::X509::Certificate.new(@apn_cert)

      @socket_tcp = TCPSocket.new(@apn_host, APN_PORT)
      @socket = OpenSSL::SSL::SSLSocket.new(@socket_tcp, ctx)
      @socket.sync = true
      @socket.connect
    rescue SocketError => error
      logger.error("Error with connection to #{@apn_host}: #{error}")
      raise "Error with connection to #{@apn_host}: #{error}"      
    end
    
    # Close open sockets
    def teardown_connection
      logger.info "Closing connections..." if @opts[:verbose]
      @socket.close if @socket
      @socket_tcp.close if @socket_tcp
    end
    
  end

end


__END__

# nc -l -p 1234 localhost

Resque.workers.map(&:unregister_worker)
require 'ruby-debug'
worker = ApplePushNotification::Sender.new(:cert_path => './certs/')
worker.very_verbose = true
worker.work(5)