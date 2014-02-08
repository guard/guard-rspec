require 'guard/rspec/inspectors/factory'
require 'guard/rspec/command'
require 'guard/rspec/formatter'
require 'guard/rspec/notifier'

module Guard
  class RSpec
    class Runner
      attr_accessor :options, :inspector, :notifier

      def initialize(options = {})
        @options = options
        @inspector = Inspectors::Factory.create(@options)
        @notifier = Notifier.new(@options)
      end

      def run_all
        paths = options[:spec_paths]
        options = @options.merge(@options[:run_all])
        return true if paths.empty?
        ::Guard::UI.info(options[:message], reset: true)
        _run(true, paths, options)
      end

      def run(paths)
        paths = inspector.paths(paths)
        return true if paths.empty?
        ::Guard::UI.info("Running: #{paths.join(' ')}", reset: true)
        _run(false, paths, options)
      end

      def reload
        inspector.reload
      end

      private

      def _run(all, paths, options)
        command = Command.new(paths, options)
        _without_bundler_env { Kernel.system(command) }.tap do |success|
          if _command_success?(success)
            summary, failed_paths = _command_output
            if summary && failed_paths
              inspector.failed(failed_paths)
              notifier.notify(summary)
              _open_launchy
              _run_all_after_pass if !all && success
            else
              notifier.notify_failure
            end
          else
            notifier.notify_failure
          end
        end
      end

      def _without_bundler_env
        if defined?(::Bundler)
          ::Bundler.with_clean_env { yield }
        else
          yield
        end
      end

      def _command_success?(success)
        return false if success.nil?
        [Command::FAILURE_EXIT_CODE, 0].include?($?.exitstatus)
      end

      def _command_output
        formatter_tmp_file = Formatter::TEMPORARY_FILE_PATH
        lines = File.readlines(formatter_tmp_file)
        [lines.first.strip, lines[1..11].map(&:strip).compact]
      rescue
        [nil, nil]
      ensure
        File.exist?(formatter_tmp_file) && File.delete(formatter_tmp_file)
      end

      def _open_launchy
        return unless options[:launchy]
        require 'launchy'
        pn = Pathname.new(options[:launchy])
        ::Launchy.open(options[:launchy]) if pn.exist?
      end

      def _run_all_after_pass
        return unless options[:all_after_pass]
        run_all
      end
    end
  end
end
