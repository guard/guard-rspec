require 'rspec/core/formatters/progress_formatter'
require "#{File.dirname(__FILE__)}/../formatter"
require "#{File.dirname(__FILE__)}/../../rspec"

class RSpec2 < RSpec::Core::Formatters::ProgressFormatter
  include Formatter
  
  def dump_summary(duration, total, failures, pending)
    super # needed to keep progress formatter
    
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end
  
end