require "apn/application"

module APNSupportingMultipleApps
  def notify_sync(token, notification)
    if notification.is_a?(Hash)
      notification.symbolize_keys!
      app_name = notification.delete(:app)
    end

    with_app(app_name) do
      super(token, notification)
    end
  end
end

module APN
  module MultipleApps
    def self.extended(mod)
      class << mod
        prepend APNSupportingMultipleApps

        delegate(*Application::DELEGATE_METHODS, to: :current_app, prefix: true, allow_nil: true)

        Application::DELEGATE_METHODS.each do |method_name|
          alias_method :"original_#{method_name}", method_name
          alias_method method_name, :"current_app_#{method_name}"
        end
      end
    end

    attr_writer :default_app_name

    def default_app_name
      @default_app_name || 'default'.freeze
    end

    def current_app_name
      @_app_name || default_app_name
    end

    def current_app
      Application::APPS[current_app_name] or \
        raise NameError, "Unregistered APN::Application `#{current_app_name}'"
    end

    def with_app(app_name)
      @_app_name, app_was = app_name.presence, @_app_name
      yield if block_given?
    ensure
      @_app_name = app_was
    end
  end
end

APN.extend APN::MultipleApps