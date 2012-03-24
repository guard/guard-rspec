require "#{File.dirname(__FILE__)}/../rspec"
require 'guard/notifier'

module Guard::RSpec::Formatter

  def guard_message(example_count, failure_count, pending_count, duration)
    message = "#{example_count} examples, #{failure_count} failures"
    if pending_count > 0
      message << " (#{pending_count} pending)"
    end
    message << "\nin #{round_float(duration)} seconds"
    message
  end

  # failed | pending | success
  def guard_image(failure_count, pending_count)
    if failure_count > 0
      :failed
    elsif pending_count > 0
      :pending
    else
      :success
    end
  end

  def priority(image)
    { :failed => 2,
      :pending => -1,
      :success => -2
    }[image]
  end

  def notify(message, image)
    Guard::Notifier.notify(message, :title => "RSpec results", :image => image,
      :priority => priority(image))
  end

private

  def round_float(float, decimals = 4)
    if Float.instance_method(:round).arity == 0 # Ruby 1.8
      factor = 10**decimals
      (float*factor).round / factor.to_f
    else # Ruby 1.9
      float.round(decimals)
    end
  end

end
