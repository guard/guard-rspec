require 'guard/rspec'
require 'rspec/core/formatters/base_formatter'

module Guard::RSpec::Formatters
  class Focuser < ::RSpec::Core::Formatters::BaseFormatter

    def dump_summary(duration, total, failures, pending)
      _write_failed_paths_in_tmp if failures > 0
    end

    private

    # Used for focus_on_failed options
    def _write_failed_paths_in_tmp
      FileUtils.mkdir_p('tmp')
      File.open('./tmp/rspec_guard_result','w') do |f|
        f.puts _failed_paths.join("\n")
      end
    rescue
      # nothing really we can do, at least don't kill the test runner
    end

    def _failed_paths
      failed = examples.select { |e| e.execution_result[:status] == 'failed' }
      failed.map { |e| e.metadata[:location] }
    end

  end
end
