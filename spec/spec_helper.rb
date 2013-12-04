require 'rspec'
require 'guard/rspec'

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

RSpec.configure do |config|
  config.color_enabled = true
  config.order = :random
  config.filter_run focus: ENV['CI'] != 'true'
  config.treat_symbols_as_metadata_keys_with_true_values = true if RSpec::Version::STRING.to_i < 3
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
