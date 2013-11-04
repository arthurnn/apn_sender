require 'spec_helper'
describe APN::Notification do

  let(:notification) do
    APN::Notification.new('token', payload)
  end

  describe ".packaged_message" do

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

  describe ".truncate_alert!" do

    before do
      APN.truncate_alert = true
    end
    after do
      APN.truncate_alert = false
    end

    context "when alert is a string" do
      let(:payload) do
        { alert: ("a" * 300) }
      end

      it "should truncate the alert" do
        notification.packaged_message.size.to_i.should == APN::Notification::DATA_MAX_BYTES
      end
    end

    context "when payload is a hash" do
      let(:payload) do
        { alert: { 'loc-args' => ["a" * 300] }}
      end

      it "should truncate the alert" do
        notification.packaged_message.size.to_i.should == APN::Notification::DATA_MAX_BYTES
      end
    end
  end
end
