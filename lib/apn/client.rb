module APN
  class Client

    DEFAULTS = {port: 2195, host: "gateway.push.apple.com"}

    def initialize(options = {})
      options = DEFAULTS.merge options.reject{|k,v| v.nil?}
      @apn_cert, @cert_pass = options[:certificate], options[:password]
      @host, @port = options[:host], options[:port]
      self
    end

    def push(message)
      socket.write(message.to_s)
      socket.flush

      if IO.select([socket], nil, nil, 1) && error = socket.read(6)
        error = error.unpack("ccN")
        APN.log(:error, "Error on message: #{error}")
        return false
      end

      APN.log(:debug, "Message sent.")
      true
    rescue OpenSSL::SSL::SSLError, Errno::EPIPE => e
      APN.log(:error, "[##{self.object_id}] Exception occurred: #{e.inspect}, socket state: #{socket.inspect}")
      reset_socket
      APN.log(:debug, "[##{self.object_id}] Socket reestablished, socket state: #{socket.inspect}")
      retry
    end

    def feedback
      if bunch = socket.read(38)
        f = bunch.strip.unpack('N1n1H140')
        APN::FeedbackItem.new(Time.at(f[0]), f[2])
      end
    end

    def socket
      @socket ||= setup_socket
    end

    private

    # Open socket to Apple's servers
    def setup_socket
      ctx = setup_certificate

      APN.log(:debug, "Connecting to #{@host}:#{@port}...")

      socket_tcp = TCPSocket.new(@host, @port)
      OpenSSL::SSL::SSLSocket.new(socket_tcp, ctx).tap do |s|
        s.sync = true
        s.connect
      end
    end

    def reset_socket
      @socket.close if @socket
      @socket = nil
      socket
    end

    def setup_certificate
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(@apn_cert)
      if @cert_pass
        ctx.key = OpenSSL::PKey::RSA.new(@apn_cert, @cert_pass)
        APN.log(:debug, "Setting up certificate using a password.")

      else
        ctx.key = OpenSSL::PKey::RSA.new(@apn_cert)
      end
      ctx
    end

  end
end
