require 'socket'
require 'openssl'
require 'resque'

module APN
  module Connection
    # APN::Connection::Base takes care of all the boring certificate loading, socket creating, and logging
    # responsibilities so APN::Sender and APN::Feedback and focus on their respective specialties.
    module Base
      attr_accessor :opts, :logger
      
      def initialize(opts = {})
        @opts = opts

        setup_logger
        log(:info, "APN::Sender initializing. Establishing connections first...") if @opts[:verbose]
        setup_paths

        super( APN::QUEUE_NAME ) if self.class.ancestors.include?(Resque::Worker)
      end
      
      # Lazy-connect the socket once we try to access it in some way
      def socket
        setup_connection unless @socket
        return @socket
      end
            
      protected
      
      # Default to Rails or Merg logger, if available
      def setup_logger
        @logger = if defined?(Merb::Logger)
          Merb.logger
        elsif defined?(::Rails.logger)
          ::Rails.logger
        end
      end
      
      # Log message to any logger provided by the user (e.g. the Rails logger).
      # Accepts +log_level+, +message+, since that seems to make the most sense,
      # and just +message+, to be compatible with Resque's log method and to enable
      # sending verbose and very_verbose worker messages to e.g. the rails logger.
      #
      # Perhaps a method definition of +message, +level+ would make more sense, but
      # that's also the complete opposite of what anyone comming from rails would expect.
      alias_method(:resque_log, :log) if defined?(log)
      def log(level, message = nil)
        level, message = 'info', level if message.nil? # Handle only one argument if called from Resque, which expects only message

        resque_log(message) if defined?(resque_log)
        return false unless self.logger && self.logger.respond_to?(level)
        self.logger.send(level, "#{Time.now}: #{message}")
      end
      
      # Log the message first, to ensure it reports what went wrong if in daemon mode. 
      # Then die, because something went horribly wrong.
      def log_and_die(msg)
        log(:fatal, msg)
        raise msg
      end
      
      def apn_production?
        @opts[:environment] && @opts[:environment] != '' && :production == @opts[:environment].to_sym
      end
      
      # Get a fix on the .pem certificate we'll be using for SSL
      def setup_paths
        @opts[:environment] ||= ::Rails.env if defined?(::Rails.env)

        # Accept a complete :full_cert_path allowing arbitrary certificate names, or create a default from the Rails env
        cert_path = @opts[:full_cert_path] || begin
          # Note that RAILS_ROOT is still here not from Rails, but to handle passing in root from sender_daemon
          @opts[:root_path] ||= defined?(::Rails.root) ? ::Rails.root.to_s : (defined?(RAILS_ROOT) ? RAILS_ROOT : '/')
          @opts[:cert_path] ||= File.join(File.expand_path(@opts[:root_path]), "config", "certs")
          @opts[:cert_name] ||= apn_production? ? "apn_production.pem" : "apn_development.pem"

          File.join(@opts[:cert_path], @opts[:cert_name])
        end
        
        @apn_cert = File.read(cert_path) if File.exists?(cert_path)
        log_and_die("Please specify correct :full_cert_path. No apple push notification certificate found in: #{cert_path}") unless @apn_cert
      end
      
      # Open socket to Apple's servers
      def setup_connection
        log_and_die("Missing apple push notification certificate") unless @apn_cert
        return true if @socket && @socket_tcp
        log_and_die("Trying to open half-open connection") if @socket || @socket_tcp

        ctx = OpenSSL::SSL::SSLContext.new
        ctx.cert = OpenSSL::X509::Certificate.new(@apn_cert)
        
        if @opts[:cert_pass]
          ctx.key = OpenSSL::PKey::RSA.new(@apn_cert, @opts[:cert_pass])
        else
          ctx.key = OpenSSL::PKey::RSA.new(@apn_cert)
        end

        @socket_tcp = TCPSocket.new(apn_host, apn_port)
        @socket = OpenSSL::SSL::SSLSocket.new(@socket_tcp, ctx)
        @socket.sync = true
        @socket.connect
      rescue SocketError => error
        log_and_die("Error with connection to #{apn_host}: #{error}")
      end

      # Close open sockets
      def teardown_connection
        log(:info, "Closing connections...") if @opts[:verbose]

        begin
          @socket.close if @socket
        rescue Exception => e
          log(:error, "Error closing SSL Socket: #{e}")
        end

        begin
          @socket_tcp.close if @socket_tcp
        rescue Exception => e
          log(:error, "Error closing TCP Socket: #{e}")
        end
      end
      
    end
  end
end
