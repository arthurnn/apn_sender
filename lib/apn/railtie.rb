module APN
  class Railtie < Rails::Railtie
    initializer "apn.setup" do |app|

      APN.root = File.join(Rails.root, "config", "certs")
      APN.certificate_name = Rails.env.development? ? "apn_development.pem" : "apn_production.pem"
      logger = Logger.new(File.join(Rails.root, 'log', 'apn_sender.log'))
      APN.logger = logger

    end
  end
end
