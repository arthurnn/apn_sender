module APN
  module Connection
    # APN::Connection::Base takes care of all the boring certificate loading, socket creating, and logging
    # responsibilities so APN::Sender and APN::Feedback and focus on their respective specialties.
    def connection_pool
      @pool ||= ConnectionPool.new(size: 1, timeout: 5) do
        APN::Client.new(host: host,
                        port: port,
                        certificate: certificate,
                        password: password)
      end
    end

    def with_connection(&block)
      connection_pool.with(&block)
    end

    attr_accessor :host, :port, :root, :full_certificate_path, :password

    def certificate
      @apn_cert ||= File.read(certificate_path)
    end

    def certificate_path
      full_certificate_path || File.join(root, certificate_name)
    end

    def certificate_name
      @cert_name || "apn_production.pem"
    end

    def certificate_name=(name)
      @cert_name = name
    end
  end
end
