# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "apn/version"

Gem::Specification.new do |s|
  s.name = %q{apn_sender}
  s.version = APN::VERSION
  s.authors = ["Kali Donovan", "Arthur Neves"]
  s.date = %q{2011-05-15}
  s.summary = "Background worker to send Apple Push Notifications over a persistent TCP socket."
  s.description = "Background worker to send Apple Push Notifications over a persistent TCP socket. Includes Resque tweaks to allow persistent sockets between jobs, helper methods for enqueueing APN notifications, and a background daemon to send them."
  s.email = %q{arthurnn@gmail.com}
  s.homepage = "http://github.com/arthurnn/apn_sender"
  s.license = "MIT"

  s.required_ruby_version     = ">= 1.9"
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency("connection_pool", [">= 0"])
  s.add_dependency("activesupport", [">= 3.1"])
  s.add_dependency("daemons")

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.require_path = 'lib'
end
