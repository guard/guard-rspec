require "#{File.dirname(__FILE__)}/../formatter"
require "spec/runner/formatter/base_formatter"

class Guard::RSpec::Formatter::NotificationSpec < Spec::Runner::Formatter::BaseFormatter
  include Guard::RSpec::Formatter

  def dump_summary(duration, total, failures, pending)
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end

end
