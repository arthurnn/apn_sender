require 'rubygems'
require 'rake'

load 'lib/apn/tasks.rb'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "apn_sender"
    gem.summary = %Q{Resque-based background worker to send Apple Push Notifications over a persistent TCP socket.}
    gem.description = %Q{Resque-based background worker to send Apple Push Notifications over a persistent TCP socket. Includes Resque tweaks to allow persistent sockets between jobs, helper methods for enqueueing APN notifications, and a background daemon to send them.}
    gem.email = "kali@deviantech.com"
    gem.homepage = "http://github.com/kdonovan/apple_push_notification"
    gem.authors = ["Kali Donovan"]
    gem.add_dependency 'resque'
    gem.add_dependency 'resque-access_worker_from_job'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "apple_push_notification #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
