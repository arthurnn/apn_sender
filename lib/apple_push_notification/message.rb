module ApplePushNotification
  # Encapsulates the logic necessary to convert an iPhone token and an array of options into a string of the format required
  # by Apple's servers to send the notification.  Much of the processing code here copied with many thanks from
  # http://github.com/samsoffes/apple_push_notification/blob/master/lib/apple_push_notification.rb
  #
  # Message.new's first argument is the token of the iPhone which should receive the message.  The second argument is a hash
  # with any of :alert, :badge, and :sound keys. All three accept string arguments, while :sound can also be set to +true+ to
  # play the default sound installed with the application.
  class Message
    attr_accessor :message
    def initialize(token, options)
      json = apple_json_array(options)
      hex_token = [token.delete(' ')].pack('H*')
      @message = "\0\0 #{hex_token}\0#{json.length.chr}#{json}"
      raise "The maximum size allowed for a notification payload is 256 bytes." if @message.size.to_i > 256
    end

    def to_s
      @message
    end
    
    protected
    
    def apple_json_array(options)
      result = {}
      result['aps'] = {}
      result['aps']['alert'] = options[:alert].to_s if options[:alert]
      result['aps']['badge'] = options[:badge].to_i if options[:badge]
      result['aps']['sound'] = options[:sound] if options[:sound] and options[:sound].is_a? String
      result['aps']['sound'] = 'default' if options[:sound] and options[:sound].is_a? TrueClass
      result.to_json
    end
  end
  
end