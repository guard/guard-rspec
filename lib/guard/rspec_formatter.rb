# NOTE: This class only exists for RSpec and should not be used by
# other classes in this project!

require "pathname"
require "fileutils"

require "rspec"
require "rspec/core/formatters/base_formatter"

module Guard
  class RSpecFormatter < ::RSpec::Core::Formatters::BaseFormatter
    TEMPORARY_FILE_PATH ||= "tmp/rspec_guard_result"

    def self.rspec_3?
      ::RSpec::Core::Version::STRING.split(".").first == "3"
    end

    if rspec_3?
      ::RSpec::Core::Formatters.register self, :dump_summary, :example_failed

      def example_failed(failure)
        examples.push failure.example
      end

      def examples
        @examples ||= []
      end
    end

    # rspec issue https://github.com/rspec/rspec-core/issues/793
    def self.extract_spec_location(metadata)
      root_metadata = metadata
      location = metadata[:location]

      until spec_path?(location)
        metadata = metadata[:example_group]

        unless metadata
          STDERR.puts "no spec file location in #{root_metadata.inspect}"
          return root_metadata[:location]
        end

        # rspec issue https://github.com/rspec/rspec-core/issues/1243
        location = (metadata[:location] || "").split(":").first
      end

      location
    end

    def self.spec_path?(path)
      path ||= ""
      flags = File::FNM_PATHNAME | File::FNM_DOTMATCH
      if File.const_defined?(:FNM_EXTGLOB) # ruby >= 2
        flags |= File::FNM_EXTGLOB
      end
      pattern = ::RSpec.configuration.pattern
      path = path.sub(/:\d+\z/, "")
      path = Pathname.new(path).cleanpath.to_s
      File.fnmatch(pattern, path, flags).tap do |result|
        STDOUT.puts "fnmatch: #{result} (#{[pattern, path, flags].inspect})"
      end
    end

    def dump_summary(*args)
      return write_summary(*args) unless self.class.rspec_3?

      notification = args[0]
      write_summary(
        notification.duration,
        notification.example_count,
        notification.failure_count,
        notification.pending_count
      )
    end

    private

    # Write summary to temporary file for runner
    def write_summary(duration, total, failures, pending)
      _write do |f|
        f.puts _message(total, failures, pending, duration)
        f.puts _failed_paths.join("\n") if failures > 0
      end
    end

    def _write(&block)
      file = File.expand_path(TEMPORARY_FILE_PATH)
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w", &block)
    end

    def _failed_paths
      klass = self.class
      failed = examples.select { |example| _status_failed?(example) }
      failed.map { |e| klass.extract_spec_location(e.metadata) }.sort.uniq
    end

    def _message(example_count, failure_count, pending_count, duration)
      message = "#{example_count} examples, #{failure_count} failures"
      if pending_count > 0
        message << " (#{pending_count} pending)"
      end
      message << " in #{duration.round(4)} seconds"
      message
    end

    def _status_failed?(example)
      if self.class.rspec_3?
        example.execution_result.status.to_s == "failed"
      else
        example.execution_result[:status].to_s == "failed"
      end
    end
  end
end
