module APN
  class Railtie < Rails::Railtie
    initializer "apn.setup" do |app|

      APN.root = File.join(Rails.root, "config", "certs")
      if Rails.env.development?
        APN.certificate_name =  "apn_development.pem"
        APN.host =  "gateway.sandbox.push.apple.com"
      end

      logger = Logger.new(File.join(Rails.root, 'log', 'apn_sender.log'))
      APN.logger = logger

    end
  end
end
