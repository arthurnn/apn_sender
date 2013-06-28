# Based roughly on delayed_job's delayed/command.rb
require 'rubygems'
require 'daemons'
require 'optparse'
require 'logger'
require 'resque'

module APN
  # A wrapper designed to daemonize an APN::Sender instance to keep in running in the background.
  # Connects worker's output to a custom logger, if available.  Creates a pid file suitable for
  # monitoring with {monit}[http://mmonit.com/monit/].
  #
  # Based off delayed_job's great example, except we can be much lighter by not loading the entire
  # Rails environment.  To use in a Rails app, <code>script/generate apn_sender</code>.
  class SenderDaemon

    def initialize(args)
      @options = {worker_count: 1, delay: 5}

      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"

        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('--cert-path=PATH', 'Path to directory containing apn .pem certificates.') do |path|
          @options[:cert_root] = path
        end
        opts.on('c', '--full-cert-path=PATH', 'Full path to desired .pem certificate.') do |path|
          @options[:full_cert_path] = path
        end
        opts.on('--cert-pass=PASSWORD', 'Password for the apn .pem certificates.') do |pass|
          @options[:cert_pass] = pass
        end
        opts.on('--cert-name=NAME', 'Certificate file name. Default: apn_production.pem') do |certificate_name|
          @options[:certificate_name] = certificate_name
        end
        opts.on('-n', '--number-of-workers=WORKERS', "Number of unique workers to spawn") do |worker_count|
          @options[:worker_count] = worker_count.to_i rescue 1
        end
        opts.on('-d', '--delay=D', "Delay between rounds of work (seconds)") do |d|
          @options[:delay] = d
        end
      end

      # If no arguments, give help screen
      @args = optparse.parse!(args.empty? ? ['-h'] : args)
    end

    def daemonize
      @options[:worker_count].times do |worker_index|
        process_name = @options[:worker_count] == 1 ? "apn_sender" : "apn_sender.#{worker_index}"
        pids_dir = defined?(Rails) ? "#{::RAILS_ROOT}/tmp/pids" : "tmp/pids"
        Daemons.run_proc(process_name, :dir => pids_dir, :dir_mode => :normal, :ARGV => @args) do |*args|
          run(process_name)
        end
      end
    end

    def run(worker_name = nil)
      APN.password = @options[:cert_pass]
      APN.full_certificate_path = @options[:full_cert_path]
      APN.root = @options[:cert_root]
      APN.certificate_name = @options[:certificate_name]

      worker = ::Resque::Worker.new(APN::Jobs::QUEUE_NAME)
      worker.work(@options[:delay])
    rescue => e
      STDERR.puts e.message
      exit 1
    end

  end
end
