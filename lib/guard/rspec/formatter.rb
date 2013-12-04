require 'guard/rspec'
require 'rspec/core/formatters/base_formatter'

module Guard
  class RSpec
    class Formatter < ::RSpec::Core::Formatters::BaseFormatter
      TEMPORARY_FILE_PATH = './tmp/rspec_guard_result'

      # Write summary to temporary file for runner
      def dump_summary(duration, total, failures, pending)
        FileUtils.mkdir_p('tmp')
        File.open(TEMPORARY_FILE_PATH, 'w') do |f|
          f.puts _message(total, failures, pending, duration)
          f.puts _failed_paths.join("\n") if failures > 0
        end
      rescue
        # nothing really we can do, at least don't kill the test runner
      end

      private

      def _failed_paths
        failed = examples.select { |e| e.execution_result[:status] == 'failed' }
        failed.map { |e| e.metadata[:location] }
      end

      def _message(example_count, failure_count, pending_count, duration)
        message = "#{example_count} examples, #{failure_count} failures"
        if pending_count > 0
          message << " (#{pending_count} pending)"
        end
        message << " in #{duration.round(4)} seconds"
        message
      end
    end
  end
end
