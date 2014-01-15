# Slight modifications from the default Resque tasks
namespace :apn do
  task :setup
  task :work => :sender
  task :workers => :senders

  desc "Start an APN worker"
  task :sender => :setup do
    require 'apn'

    unless defined?(Resque)
      puts "This rake task is only for resque workers"
      return
    end

    APN.backend = :resque
    APN.password = ENV['CERT_PASS']
    APN.full_certificate_path =  ENV['FULL_CERT_PATH']
    APN.logger = Rails.logger

    worker = ::Resque::Worker.new(APN::Jobs::QUEUE_NAME)

    puts "*** Starting worker to send apple notifications in the background from #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple APN workers. Should only be used in dev mode."
  task :senders do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake apn:work"
      end
    end

    threads.each { |thread| thread.join }
  end
end
