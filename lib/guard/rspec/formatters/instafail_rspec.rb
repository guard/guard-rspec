# Inspired from https://github.com/grosser/rspec-instafail/blob/master/lib/rspec/instafail.rb
require "#{File.dirname(__FILE__)}/../formatter"
require 'rspec/core/formatters/progress_formatter'

class InstafailRSpec < RSpec::Core::Formatters::ProgressFormatter
  include Formatter
  
  def dump_summary(duration, total, failures, pending)
    super # needed to keep progress formatter
    
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end
  
  def example_failed(example)
    @counter ||= 0
    @counter += 1
    result = example.metadata[:execution_result]
    exception = result[:exception_encountered] || result[:exception] # rspec 2.0 || rspec 2.2
    short_padding = '  '
    padding = '     '
    output.puts
    output.puts "#{short_padding}#{@counter}) #{example.full_description}"
    output.puts "#{padding}#{red("Failure/Error:")} #{red(read_failed_line(exception, example).strip)}"
    output.puts "#{padding}#{red(exception)}"
    format_backtrace(exception.backtrace, example).each do |backtrace_info|
      output.puts grey("#{padding}# #{backtrace_info}")
    end
    output.flush
  end
  
end