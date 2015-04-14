class Payload

  def initialize(notification_hash, max_bytes)
    @notification_hash = notification_hash
    @max_bytes = max_bytes
  end

  def package
    str = encode(@notification_hash)

    if APN.truncate_alert && str.bytesize > @max_bytes
      max_bytesize = @max_bytes - (str.bytesize - alert.bytesize)

      if max_bytesize <= 0
        escaped_max_bytesize = @max_bytes - (str.bytesize - encode(alert).bytesize)
        raise "Even truncating the alert won't be enough to have a #{@max_bytes} message" if escaped_max_bytesize <= 0
        truncate_escaped!(escaped_max_bytesize)
      else
        truncate_alert!(max_bytesize)
      end
      str = encode(@notification_hash)
    end
    str
  end

  private

    def alert
      @alert ||=
      if hash_alert?
        @notification_hash['aps']['alert']['loc-args'][0]
      else
        @notification_hash['aps']['alert']
      end
    end

    def alert=(value)
      if hash_alert?
        @notification_hash['aps']['alert']['loc-args'][0] = value
      else
        @notification_hash['aps']['alert'] = value
      end
    end

    def hash_alert?
      @hash_alert ||= @notification_hash['aps']['alert'].is_a?(Hash)
    end

    def truncate_alert!(max_size)
      self.alert = alert.mb_chars.limit(max_size).to_s
    end

    def truncate_escaped!(max_size)
      self.alert = alert.each_char.each_with_object('') do |char, result|
        if encoded_size(result) + encoded_size(char) > max_size
          break result
        else
          result << char
        end
      end
    end

    def encode(obj)
      ActiveSupport::JSON.encode(obj)
    end

    def encoded_size(str)
      encode(str).bytesize - 2
    end
end
