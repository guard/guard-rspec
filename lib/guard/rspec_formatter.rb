# NOTE: This class only exists for RSpec and should not be used by
# other classes in this project!

require "pathname"
require "fileutils"

require "rspec"
require "rspec/core/formatters/base_formatter"

require "guard/rspec_defaults"

module Guard
  class RSpecFormatter < ::RSpec::Core::Formatters::BaseFormatter
    WIKI_ENV_WARN_URL =
      "https://github.com/guard/guard-rspec/wiki/Warning:-no-environment"

    NO_ENV_WARNING_MSG = "no environment passed - see #{WIKI_ENV_WARN_URL}"
    NO_RESULTS_VALUE_MSG = ":results_file value unknown (using defaults)"

    UNSUPPORTED_PATTERN = "Your RSpec.configuration.pattern uses characters "\
      "unsupported by your Ruby version (File::FNM_EXTGLOB is undefined)"

    class Error < RuntimeError
      class UnsupportedPattern < Error
        def initialize(msg = UNSUPPORTED_PATTERN)
          super
        end
      end
    end

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
        metadata = metadata[:parent_example_group] || metadata[:example_group]

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
      pattern = ::RSpec.configuration.pattern

      flags = File::FNM_PATHNAME | File::FNM_DOTMATCH
      if File.const_defined?(:FNM_EXTGLOB) # ruby >= 2
        flags |= File::FNM_EXTGLOB
      elsif pattern =~ /[{}]/
        fail Error::UnsupportedPattern
      end

      path ||= ""
      path = path.sub(/:\d+\z/, "")
      path = Pathname.new(path).cleanpath.to_s
      File.fnmatch(pattern, path, flags)
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
      file = _results_file
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

    def _results_file
      path = ENV["GUARD_RSPEC_RESULTS_FILE"]
      if path.nil?
        STDERR.puts "Guard::RSpec: Warning: #{NO_ENV_WARNING_MSG}\n" \
          "Guard::RSpec: Warning: #{NO_RESULTS_VALUE_MSG}"
        path = RSpecDefaults::TEMPORARY_FILE_PATH
      end

      File.expand_path(path)
    end
  end
end
