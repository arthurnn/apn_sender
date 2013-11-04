# -*- coding: utf-8 -*-
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
