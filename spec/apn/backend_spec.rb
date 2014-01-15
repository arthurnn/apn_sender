require 'spec_helper'
describe APN::Backend do

  context "when not setting any backend" do

    it "is a simple backend" do
      expect(APN.backend).to be_a(APN::Backend::Simple)
    end
  end

  context "when setting a nil backend" do

    before do
      APN.backend = nil
    end

    it "is a simple backend" do
      expect(APN.backend).to be_a(APN::Backend::Simple)
    end
  end

  if defined? Sidekiq
    context "when setting a sidekiq backend" do

      before do
        APN.backend = :sidekiq
      end

      it "is a simple backend" do
        expect(APN.backend).to be_a(APN::Backend::Sidekiq)
      end
    end
  end

  if defined? Resque
    context "when setting a resque backend" do

      before do
        APN.backend = :resque
      end

      it "is a simple backend" do
        expect(APN.backend).to be_a(APN::Backend::Resque)
      end
    end
  end
end
