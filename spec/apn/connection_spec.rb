require 'spec_helper'
describe APN::Connection do

  module MockConnection
    class << self
      include APN::Connection
    end
  end

  describe ".certificate_path" do

    context "when changing the root" do

      let(:root) do
        File.expand_path File.join(File.dirname(__FILE__), '..')
      end

      before do
        MockConnection.root = root
      end

      after do
        MockConnection.root = nil
      end

      it "returns path relative to root" do
        MockConnection.certificate_path.should =~ /^#{Regexp.escape(root)}/
      end
    end

    context "when changing the full_certificate_path" do

      let(:path) do
        File.expand_path File.join(File.dirname(__FILE__), '..', 'cert.pem')
      end

      before do
        MockConnection.full_certificate_path = path
      end

      after do
        MockConnection.full_certificate_path = nil
      end

      it "returns abosulute path" do
        expect(MockConnection.certificate_path).to eq(path)
      end
    end
  end

  describe ".certificate_name" do

    context "when changing certificate name" do

      before do
        MockConnection.certificate_name = "name"
      end

      after do
        MockConnection.certificate_name = nil
      end

      it "returns the new name" do
        expect(MockConnection.certificate_name).to eq("name")
      end
    end

    context "when not changing certificate name" do

      it "returns the default" do
        expect(MockConnection.certificate_name).to eq("apn_production.pem")
      end
    end
  end
end
