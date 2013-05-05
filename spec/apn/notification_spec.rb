require 'spec_helper'
describe APN::Notification do

  describe ".packaged_message" do

    let(:notification) do
      APN::Notification.new('token', payload)
    end

    let(:message) do
      notification.packaged_message
    end

    context "when payload is a string" do

      let(:payload) do
        "hi"
      end

      it "adds 'aps' key" do
        expect(ActiveSupport::JSON::decode(message)).to have_key('aps')
      end

      it "encode the payload" do
        expect(message)
          .to eq(ActiveSupport::JSON::encode(aps: {alert: payload}))
      end
    end

    context "when payload is a hash" do

      let(:payload) do
        {alert: 'paylod'}
      end

      it "adds 'aps' key" do
        expect(ActiveSupport::JSON::decode(message)).to have_key('aps')
      end

      it "encode the payload" do
        expect(message)
          .to eq(ActiveSupport::JSON::encode(aps: payload))
      end
    end

    context "when payload is Localizable" do
      pending
    end
  end

  describe ".packaged_token" do
    pending
  end
end
