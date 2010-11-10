require "#{File.dirname(__FILE__)}/../formatter"
require 'spec/runner/formatter/progress_bar_formatter'

class DefaultSpec < Spec::Runner::Formatter::ProgressBarFormatter
  include Formatter
  
  def dump_summary(duration, total, failures, pending)
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end
end