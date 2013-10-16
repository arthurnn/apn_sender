$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

begin
  require 'sidekiq'
rescue LoadError
end

begin
  require 'resque'
rescue LoadError
end

require "apn"
require "rspec"

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end

## preload the apn backend
APN.backend
