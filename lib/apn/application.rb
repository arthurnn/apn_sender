require "apn/connection"

module APN
  class Application
    include Connection

    APPS = {}
    OPTION_KEYS = [:pool_size, :pool_timeout, :host, :port, :root, :full_certificate_path, :password, :certificate_name].freeze
    DELEGATE_METHODS = [:with_connection, :connection_pool].concat(OPTION_KEYS)

    attr_reader :name

    def initialize(name, options = {})
      @name = name.to_s

      OPTION_KEYS.each do |key|
        self.send("#{key}=", options.fetch(key) { APN.send("original_#{key}") } )
      end
    end

    def to_h
      Hash[OPTION_KEYS.zip(OPTION_KEYS.map(&method(:send)))]
    end

    def == other
      if other.is_a?(APN::Application)
        to_h == other.to_h
      else
        super(other)
      end
    end

    def self.register(*args)
      new(*args).tap { |app| APPS[app.name] = app if app.certificate }
    end
  end
end