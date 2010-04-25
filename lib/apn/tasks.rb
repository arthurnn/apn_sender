# Slight modifications from the default Resque tasks
namespace :apn do
  task :setup
  task :sender => :work
  task :senders => :workers  

  desc "Start an APN worker"
  task :work => :setup do
    require 'lib/apple_push_notification'

    worker = nil

    begin
      worker = APN::Sender.new(:cert_path => ENV['CERT_PATH'], :environment => ENV['ENVIRONMENT'])
      worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      worker.very_verbose = ENV['VVERBOSE']
    rescue Exception => e
      raise e
      # abort "set QUEUE env var, e.g. $ QUEUE=critical,high rake resque:work"
    end

    puts "*** Starting worker to send apple notifications in the background from #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple APN workers. Should only be used in dev mode."
  task :workers do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake apn:work"
      end
    end

    threads.each { |thread| thread.join }
  end
end