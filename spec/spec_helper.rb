require 'rspec'
require 'guard/rspec'
Guard::UI.options = { :level => :warn }

RSpec.configure do |config|
  config.color_enabled = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do
    @fixture_path = Pathname.new(File.expand_path('../fixtures/', __FILE__))
    @lib_path     = Pathname.new(File.expand_path('../../lib/', __FILE__))
  end
end

# Creates a stub that falls back to original behavior unless an argument matcher matches.
# Example:
#   stub_with_fallback(File, :exist?).with(/txt/).and_return(true)
#   # calls unstubbed File.exist? for anything that doesn't match /txt/.
def stub_with_fallback(obj, method)
  original_method = obj.method(method)
  obj.stub(method).with(anything()) { |*args| original_method.call(*args) }
  return obj.stub(method)
end
