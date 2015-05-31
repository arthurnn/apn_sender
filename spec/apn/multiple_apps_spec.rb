require 'spec_helper'

if ENV['APN_MULTIPLE_APPS'] == 'true'
  describe APN::MultipleApps do
    class APN::Application
      def certificate
        @apn_cert ||= "APN Certificate for `#{name}' from #{certificate_path}"
      end

      def with_connection
        yield APN::Client.new(host: host, port: port, certificate: certificate, password: password)
      end
    end

    let(:root) { File.expand_path File.join(File.dirname(__FILE__), '..') }
    before { APN.root = root }
    after  { APN.root = nil }

    let(:default_app) { APN::Application.register('default', certificate_name: 'default_apn_certificate.pem') }
    let(:other_app)   { APN::Application.register('other', certificate_name: 'other_apn_certificate.pem') }

    it { expect(default_app).to be_instance_of APN::Application }
    it { expect(other_app).to be_instance_of APN::Application }

    describe '.default_app_name' do
      let(:custom_app_name) { 'custom' }
      before { APN.default_app_name = custom_app_name }
      after  { APN.remove_instance_variable :@default_app_name }
      it { expect(APN.default_app_name).to eq custom_app_name }
    end

    describe '.with_app' do
      context 'with a missing app name as an argument' do
        around { |ex| APN.with_app('missing', &ex) }
        it { expect { APN.current_app }.to raise_error(NameError) }
      end

      context 'with the registered app name as an argument' do
        around { |ex| APN.with_app('other', &ex) }
        it { expect(APN.current_app).to eq other_app }
      end

      context 'without arguments' do
        around { |ex| APN.with_app(nil, &ex) }
        it { expect(APN.current_app).to eq default_app }

        context 'when the default app name is changed' do
          before { APN.default_app_name = 'other' }
          after  { APN.remove_instance_variable :@default_app_name }
          it { expect(APN.current_app).to eq other_app }
        end
      end
    end

    describe '.notify_sync_with_app' do
      let(:socket)       { double("SSLSocket") }
      let(:token)        { "2589b1aa 363d23d8 d7f16695 1a9e3ff4 1fb0130a 637d6997 a2080d88 1b2a19b5" }
      let(:client_args)  { other_app.to_h.slice(:host, :port, :password).merge(certificate: other_app.certificate) }
      let(:client)       { APN::Client.new(client_args) }
      let(:notification) { APN::Notification.new(token.gsub(/\W/, ''), alert: "hi")}

      before do
        client.should_receive(:socket).at_least(1).and_return(socket)
        IO.should_receive(:select).and_return(false)
      end

      context 'when payload is a hash containing app name' do
        it 'remove app name from payload' do
          APN::Client.should_receive(:new).with(client_args).and_return(client)
          socket.stub(:flush)
          socket.should_receive(:write).with(notification.to_s)
          APN.notify_sync(token, alert: "hi", app: "other")
        end
      end
    end
  end
end