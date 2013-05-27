require 'spec_helper'
describe APN::Client do

  describe ".push" do

    let(:socket) { double("socket") }

    let(:client) do
      APN::Client.new
    end

    before do
      client.should_receive(:socket).and_return(socket)
    end

    context "when pushing a message" do

      it "sends write to socket" do
        socket.should_receive(:write).with("hi")
        client.push("hi")
      end
    end
  end

  describe ".socket" do

  end
end
