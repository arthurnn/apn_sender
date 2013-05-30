module APN
  # Encapsulates data returned from the {APN Feedback Service}[http://developer.apple.com/iphone/library/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW3].
  # Possesses +timestamp+ and +token+ attributes.
  class FeedbackItem
    attr_accessor :timestamp, :token

    def initialize(time, token)
      @timestamp = time
      @token = token
    end

    # For convenience, return the token on to_s
    def to_s
      token
    end
  end

  # When supplied with the certificate path and the desired environment, connects to the {APN Feedback Service}[http://developer.apple.com/iphone/library/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW3]
  # and returns any response as an array of APN::FeedbackItem elements.
  #
  # See README for usage and details.
  class Feedback

    def initialize(options = {})
      @apn_host, @apn_port = options[:host], options[:port]
    end

    # Returns array of APN::FeedbackItem elements read from Apple. Connects to Apple once and caches the
    # data, continues to returns cached data unless called with <code>data(true)</code>, which clears the
    # existing feedback array.  Note that once you force resetting the cache you loose all previous feedback,
    # so be sure you've already processed it.
    def data(force = nil)
      @feedback = nil if force
      @feedback ||= receive
    end

    # Wrapper around +data+ returning just an array of token strings.
    def tokens(force = nil)
      data(force).map(&:token)
    end

    # Prettify to return meaningful status information when printed. Can't add these directly to connection/base, because Resque depends on decoding to_s
    def inspect
      "#<#{self.class.name}: #{to_s}>"
    end

    # Prettify to return meaningful status information when printed. Can't add these directly to connection/base, because Resque depends on decoding to_s
    def to_s
      "#{@socket ? 'Connected' : 'Connection not currently established'} to #{host} on #{port}"
    end

    protected

    # Connects to Apple's Feedback Service and checks if there's anything there for us.
    # Returns an array of APN::FeedbackItem pairs
    def receive
      feedbacks = []
      while f = client.feedback
        feedbacks << f
      end
      return feedbacks
    end

    def client
      @client ||= APN::Client.new(host: host,
                                  port: port,
                                  certificate: APN.certificate,
                                  password: APN.password)
    end

    def host
      @apn_host || "feedback.push.apple.com"
    end

    def port
      @apn_port || 2196
    end
  end
end
