require 'guard/rspec'
require 'rspec/core/formatters/base_formatter'

module Guard
  class RSpec
    class Formatter < ::RSpec::Core::Formatters::BaseFormatter
      TEMPORARY_FILE_PATH = './tmp/rspec_guard_result'

      def self.extract_spec_location(metadata)
        root_metadata = metadata
        until spec_path?(metadata[:location])
          metadata = metadata[:example_group]
          if !metadata
            warn "no spec file found for #{root_metadata[:location]}"
            return root_metadata[:location]
          end
        end
        metadata[:location]
      end

      def self.spec_path?(path)
        flags = File::FNM_PATHNAME | File::FNM_DOTMATCH
        if File.const_defined?(:FNM_EXTGLOB) # ruby >= 2
          flags |= File::FNM_EXTGLOB
        end
        File.fnmatch(::RSpec.configuration.pattern, path.sub(/:\d+\z/, ''), flags)
      end

      # Write summary to temporary file for runner
      def dump_summary(duration, total, failures, pending)
        write do |f|
          f.puts _message(total, failures, pending, duration)
          f.puts _failed_paths.join("\n") if failures > 0
        end
      rescue
        # nothing really we can do, at least don't kill the test runner
      end

      private

      def write(&block)
        FileUtils.mkdir_p('tmp')
        File.open(TEMPORARY_FILE_PATH, 'w', &block)
      end

      def _failed_paths
        failed = examples.select { |e| e.execution_result[:status] == 'failed' }
        failed.map { |e| self.class.extract_spec_location(e.metadata) }
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
