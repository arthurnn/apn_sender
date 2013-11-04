# -*- coding: utf-8 -*-
require 'spec_helper'
describe APN::Notification do

  let(:token) { "2589b1aa 363d23d8 d7f16695 1a9e3ff4 1fb0130a 637d6997 a2080d88 1b2a19b5" }
  let(:payload) {"fake"}
  let(:notification) do
    APN::Notification.new(token, payload)
  end

  describe ".packaged_message" do

    let(:message) do
      notification.packaged_message
    end

    context "when payload is a string" do
      let(:payload) { "hi" }

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

    context "when payload is over 256 bytes" do
      let(:payload) { "»" * 200 }

      it "raises" do
        expect {
          notification.packaged_message
        }.to raise_error
      end
    end

    context "when payload is Localizable" do
      pending
    end
  end

  describe ".packaged_token" do

    context "when is a valid token" do

      it "has 32 byte size" do
        expect(notification.packaged_token.bytesize).to eq(32)
      end
    end

    context "when token doesnt have spaces" do
      let(:token) { "2589b1aa363d23d8d7f166951a9e3ff41fb0130a637d6997a2080d881b2a19b5" }

      it "has 32 byte size" do
        expect(notification.packaged_token.bytesize).to eq(32)
      end
    end

    context "when token is more that 32 bytes" do
      let(:token) { "9b1e2" * 50 }

      it "raises" do
        pending
      end
    end
  end

  describe ".truncate_alert!" do

    before do
      APN.truncate_alert = true
    end
    after do
      APN.truncate_alert = false
    end

    context "when alert is a string" do
      let(:payload) { "a" * 300 }

      it "truncates the alert" do
        expect(notification.packaged_message.size.to_i).to eq(APN::Notification::DATA_MAX_BYTES)
      end

      it "has payload size equals payload byte size" do
        expect(notification.packaged_message.size.to_i).to eq(notification.payload_size)
      end

      it "has payload truncated only the alert" do
        expect(notification.packaged_message).to eq({aps:{alert: "a" * 236 }}.to_json)
      end
    end

    context "when payload is a hash" do
      let(:payload) do
        { alert: { 'loc-args' => ["a" * 300] }}
      end

      it "truncates the alert" do
        expect(notification.packaged_message.size.to_i).to eq(APN::Notification::DATA_MAX_BYTES)
      end

      it "has payload size equals payload byte size" do
        expect(notification.packaged_message.size.to_i).to eq(notification.payload_size)
      end
    end

    context "when payload is multibyte string" do
      let(:payload) { "»" * 256 }

      it "truncates the alert" do
        expect(notification.payload_size).to eq(APN::Notification::DATA_MAX_BYTES)
      end

      it "has different payload size and message size" do
        expect(notification.packaged_message.size.to_i).to_not eq(notification.payload_size)
      end
    end
  end
end
