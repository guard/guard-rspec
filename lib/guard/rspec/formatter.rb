require 'guard/rspec'
require 'guard/notifier'
require "rspec/core/formatters/base_formatter"

class Guard::RSpec::Formatter < RSpec::Core::Formatters::BaseFormatter

  def dump_summary(duration, total, failures, pending)
    failed_specs = examples.delete_if{|e| e.execution_result[:status] != "failed"}.map{|s| s.metadata[:location]}

    # if this fails don't kill everything
    begin
      FileUtils.mkdir_p('tmp')
      File.open("./tmp/rspec_guard_result","w") do |f|
        f.puts failed_specs.join("\n")
      end
    rescue
      # nothing really we can do, at least don't kill the test runner
    end

    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end

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
