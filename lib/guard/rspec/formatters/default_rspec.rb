require "#{File.dirname(__FILE__)}/../formatter"
require 'rspec/core/formatters/progress_formatter'

class DefaultRSpec < RSpec::Core::Formatters::ProgressFormatter
  include Guard::Rspec::Formatter
  
  def dump_summary(duration, total, failures, pending)
    super # needed to keep progress formatter
    
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end
end
