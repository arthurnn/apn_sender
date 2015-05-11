require 'apn/payload'

module APN
  # Encapsulates the logic necessary to convert an iPhone token and an array of options into a string of the format required
  # by Apple's servers to send the notification.  Much of the processing code here copied with many thanks from
  # http://github.com/samsoffes/apple_push_notification/blob/master/lib/apple_push_notification.rb
  #
  # APN::Notification.new's first argument is the token of the iPhone which should receive the notification.  The second argument
  # is a hash with any of :alert, :badge, and :sound keys. All three accept string arguments, while :sound can also be set to +true+
  # to play the default sound installed with the application. At least one of these keys must exist.  Any other keys are merged into
  # the root of the hash payload ultimately sent to the iPhone:
  #
  #   APN::Notification.new(token, {:alert => 'Stuff', :custom => {:code => 23}})
  #   # Writes this JSON to servers: {"aps" => {"alert" => "Stuff"}, "custom" => {"code" => 23}}
  #
  # As a shortcut, APN::Notification.new also accepts a string as the second argument, which it converts into the alert to send.  The
  # following two lines are equivalent:
  #
  #   APN::Notification.new(token, 'Some Alert')
  #   APN::Notification.new(token, {:alert => 'Some Alert'})
  #
  class Notification
    # Available to help clients determine before they create the notification if their message will be too large.
    # Each iPhone Notification payload must be 256 or fewer characters (not including the token or other push data), see Apple specs at:
    # https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4
    DATA_MAX_BYTES = 2047

    attr_accessor :options, :token
    def initialize(token, opts)
      @options = opts.is_a?(Hash) ? opts.symbolize_keys : {:alert => opts}
      @token = token

      raise "The maximum size allowed for a notification payload is #{DATA_MAX_BYTES} bytes." if payload_size > DATA_MAX_BYTES
    end

    def to_s
      packaged_notification
    end

    def payload_size
      packaged_message.bytesize
    end

    # Ensures at least one of <code>%w(alert badge sound)</code> is present
    def valid?
      return true if [:alert, :badge, :sound].any?{|key| options.keys.include?(key) }
      false
    end

    # Completed encoded notification, ready to send down the wire to Apple
    def packaged_notification
      pt = packaged_token
      pm = packaged_message
      [0, 0, 32, pt, 0, payload_size, pm].pack("ccca*cca*")
    end

    # Device token, compressed and hex-ified
    def packaged_token
      [@token.gsub(/[\s|<|>]/,'')].pack('H*')
    end

    # Converts the supplied options into the JSON needed for Apple's push notification servers.
    # Extracts :alert, :badge, :sound and :category keys into the 'aps' hash, merges any other hash data
    # into the root of the hash to encode and send to apple.
    def packaged_message
      @packaged_message ||=
        begin
          opts = @options.dup
          hsh = {'aps' => {}}
          if alert = opts.delete(:alert)
            alert = alert.to_s unless alert.is_a?(Hash)
            hsh['aps']['alert'] = alert
          end
          hsh['aps']['badge'] = opts.delete(:badge).to_i if opts[:badge]
          hsh['aps']['category'] = opts.delete(:category).to_s if opts[:category]
          if sound = opts.delete(:sound)
            hsh['aps']['sound'] = sound.is_a?(TrueClass) ? 'default' : sound.to_s
          end
          if content_available = opts.delete(:content_available)
            hsh['aps']['content-available'] = 1 if [1,true].include? content_available
          end
          hsh.merge!(opts)
          Payload.new(hsh, DATA_MAX_BYTES).package
        end
    end
  end
end
