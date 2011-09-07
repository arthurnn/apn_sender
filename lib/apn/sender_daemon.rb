# Based roughly on delayed_job's delayed/command.rb
require 'rubygems'
require 'daemons'
require 'optparse'
require 'logger'

module APN
  # A wrapper designed to daemonize an APN::Sender instance to keep in running in the background.
  # Connects worker's output to a custom logger, if available.  Creates a pid file suitable for
  # monitoring with {monit}[http://mmonit.com/monit/].
  #
  # Based off delayed_job's great example, except we can be much lighter by not loading the entire
  # Rails environment.  To use in a Rails app, <code>script/generate apn_sender</code>.
  class SenderDaemon
    
    def initialize(args)
      @options = {:worker_count => 1, :environment => :development, :delay => 5}
      
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"

        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-e', '--environment=NAME', 'Specifies the environment to run this apn_sender under ([development]/production).') do |e|
          @options[:environment] = e
        end
        opts.on('--cert-path=NAME', 'Path to directory containing apn .pem certificates.') do |path|
          @options[:cert_path] = path
        end
        opts.on('c', '--full-cert-path=NAME', 'Full path to desired .pem certificate (overrides environment selector).') do |path|
          @options[:full_cert_path] = path
        end
        opts.on('--cert-pass=PASSWORD', 'Password for the apn .pem certificates.') do |pass|
          @options[:cert_pass] = pass
        end
        opts.on('-n', '--number-of-workers=WORKERS', "Number of unique workers to spawn") do |worker_count|
          @options[:worker_count] = worker_count.to_i rescue 1
        end
        opts.on('-v', '--verbose', "Turn on verbose mode") do
          @options[:verbose] = true
        end
        opts.on('-V', '--very-verbose', "Turn on very verbose mode") do
          @options[:very_verbose] = true
        end
        opts.on('-d', '--delay=D', "Delay between rounds of work (seconds)") do |d|
          @options[:delay] = d
        end
      end
      
      # If no arguments, give help screen
      @args = optparse.parse!(args.empty? ? ['-h'] : args)
      @options[:verbose] = true if @options[:very_verbose]
    end
  
    def daemonize
      @options[:worker_count].times do |worker_index|
        process_name = @options[:worker_count] == 1 ? "apn_sender" : "apn_sender.#{worker_index}"
        Daemons.run_proc(process_name, :dir => "#{::RAILS_ROOT}/tmp/pids", :dir_mode => :normal, :ARGV => @args) do |*args|
          run process_name
        end
      end
    end
    
    def run(worker_name = nil)
      logger = Logger.new(File.join(::RAILS_ROOT, 'log', 'apn_sender.log'))
      
      worker = APN::Sender.new(@options)
      worker.logger = logger
      worker.verbose = @options[:verbose]
      worker.very_verbose = @options[:very_verbose]
      worker.work(@options[:delay])
    rescue => e
      STDERR.puts e.message
      logger.fatal(e) if logger && logger.respond_to?(:fatal)
      exit 1
    end
    
  end
end
