require "guard/rspec/command"

module Guard
  class RSpec < Plugin
    class RSpecProcess
      class Failure < RuntimeError
      end

      attr_reader :results

      def initialize(command, formatter_tmp_file)
        @command = command
        @formatter_tmp_file = formatter_tmp_file
        @results = nil

        @exit_code = _run
        @results = _read_results
      end

      def all_green?
        exit_code.zero?
      end

      private

      def _run
        _without_bundler_env do
          exit_code = _really_run
          unless [0, Command::FAILURE_EXIT_CODE].include?(exit_code)
            fail Failure, "Failed: #{command.inspect} (exit code: #{exit_code})"
          end
          exit_code
        end
      end

      def _really_run
        env = { "GUARD_RSPEC_RESULTS_FILE" => formatter_tmp_file }
        pid = Kernel.spawn(env, command) # use spawn to stub in JRuby
        result = ::Process.wait2(pid)
        result.last.exitstatus
      rescue Errno::ENOENT => ex
        fail Failure, "Failed: #{command.inspect} (#{ex})"
      end

      def _read_results
        Results.new(formatter_tmp_file)
      ensure
        File.delete(formatter_tmp_file) if File.exist?(formatter_tmp_file)
      end

      def _without_bundler_env
        if defined?(::Bundler)
          ::Bundler.with_clean_env { yield }
        else
          yield
        end
      end

      private

      attr_reader :command
      attr_reader :exit_code
      attr_reader :formatter_tmp_file
    end
  end
end
