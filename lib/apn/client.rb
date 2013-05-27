module APN
  class Client

    def initialize(options = {})
      defaults = {port: 2195, host: "gateway.push.apple.com"}
      options = defaults.merge(options)
      @apn_cert, @cert_pass = options[:certificate], options[:password]
      @host, @port = options[:host], options[:port]
      self
    end

    def push(message)
      socket.write(message)
    end

    def socket
      @socket ||= setup_socket
    end

    private
    # Open socket to Apple's servers
    def setup_socket
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(@apn_cert)
      if @cert_pass
        ctx.key = OpenSSL::PKey::RSA.new(@apn_cert, @cert_pass)
      else
        ctx.key = OpenSSL::PKey::RSA.new(@apn_cert)
      end

      socket_tcp = TCPSocket.new(@host, @port)
      OpenSSL::SSL::SSLSocket.new(socket_tcp, ctx).tap do |s|
        s.sync = true
        s.connect
      end
      #      rescue SocketError => error
      #        log_and_die("Error with connection to #{apn_host}: #{error}")
    end

  end
end
