require 'rspec'
require 'guard/rspec'

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

rspec_major_version = RSpec::Version::STRING.to_i

RSpec.configure do |config|
  if rspec_major_version < 3
    config.color_enabled = true
    config.treat_symbols_as_metadata_keys_with_true_values = true
  else
    config.color = true
  end
  config.order = :random
  config.filter_run focus: ENV['CI'] != 'true'
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
