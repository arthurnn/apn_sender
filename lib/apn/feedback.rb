require 'apn/connection/base'

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
    include APN::Connection::Base
        
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
      "#{@socket ? 'Connected' : 'Connection not currently established'} to #{apn_host} on #{apn_port}"
    end
    
    protected
        
    # Connects to Apple's Feedback Service and checks if there's anything there for us.  
    # Returns an array of APN::FeedbackItem pairs
    def receive
      feedback = []

      # Hi Apple
      setup_connection

      # Unpacking code borrowed from http://github.com/jpoz/APNS/blob/master/lib/apns/core.rb
      while line = socket.gets   # Read lines from the socket
        line.strip!
        f = line.unpack('N1n1H140')
        feedback << APN::FeedbackItem.new(Time.at(f[0]), f[2])
      end

      # Bye Apple
      teardown_connection

      return feedback
    end
    
    
    def apn_host
      @apn_host ||= apn_production? ? "feedback.push.apple.com" : "feedback.sandbox.push.apple.com"
    end
    
    def apn_port
      2196
    end
    
  end
end



__END__
# Testing from irb
irb -r 'lib/apn/feedback'

a=APN::Feedback.new(:cert_path => '/Users/kali/Code/insurrection/certs/', :environment => :production)