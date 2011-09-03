require "#{File.dirname(__FILE__)}/../formatter"
require "rspec/core/formatters/base_formatter"

class Guard::RSpec::Formatter::NotificationRSpec < RSpec::Core::Formatters::BaseFormatter
  include Guard::RSpec::Formatter

  def dump_summary(duration, total, failures, pending)
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end

end
