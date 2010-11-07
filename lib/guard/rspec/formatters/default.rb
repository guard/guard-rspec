require "#{File.dirname(__FILE__)}/../formatter"

if defined?(Spec)
  # RSpec 1.x
  require 'spec/runner/formatter/progress_bar_formatter'
  class Default < Spec::Runner::Formatter::ProgressBarFormatter
    include Formatter
    
    def dump_summary(duration, total, failures, pending)
      message = guard_message(total, failures, pending, duration)
      image   = guard_image(failures, pending)
      notify(message, image)
    end
  end
else
  # RSpec 2.x
  require 'rspec/core/formatters/progress_formatter'
  class Default < RSpec::Core::Formatters::ProgressFormatter
    include Formatter
    
    def dump_summary(duration, total, failures, pending)
      super # needed to keep progress formatter
      
      message = guard_message(total, failures, pending, duration)
      image   = guard_image(failures, pending)
      notify(message, image)
    end
  end
end