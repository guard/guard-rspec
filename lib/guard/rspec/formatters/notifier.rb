require 'guard/rspec'
require 'guard/notifier'
require 'rspec/core/formatters/base_formatter'

module Guard::RSpec::Formatters
  class Notifier < ::RSpec::Core::Formatters::BaseFormatter

    def dump_summary(duration, total, failures, pending)
      message = _message(total, failures, pending, duration)
      status  = _status(failures, pending)
      _notify(message, status)
    end

    private

    def _message(example_count, failure_count, pending_count, duration)
      message = "#{example_count} examples, #{failure_count} failures"
      if pending_count > 0
        message << " (#{pending_count} pending)"
      end
      message << "\nin #{duration.round(4)} seconds"
      message
    end

    def _status(failure_count, pending_count)
      if failure_count > 0
        :failed
      elsif pending_count > 0
        :pending
      else
        :success
      end
    end

    def _notify(message, status)
      ::Guard::Notifier.turn_on(silent: true)
      ::Guard::Notifier.notify(message, title: 'RSpec results', image: status, priority: _priority(status))
    end

    def _priority(status)
      { failed:   2,
        pending: -1,
        success: -2
      }[status]
    end

  end
end
