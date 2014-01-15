require 'spec_helper'

if defined? Sidekiq
  require 'apn/backend/sidekiq'
  describe APN::Jobs::SidekiqNotificationJob do

    it { should be_a(Sidekiq::Worker) }

    it "has the right queue name" do
      expect(subject.class.instance_variable_get(:@queue)).to eq(APN::Jobs::QUEUE_NAME)
    end
  end
end

if defined? Resque
  require 'apn/backend/resque'
  describe APN::Jobs::ResqueNotificationJob do

    it "has the right queue name" do
      expect(subject.class.instance_variable_get(:@queue)).to eq(APN::Jobs::QUEUE_NAME)
    end
  end
end
