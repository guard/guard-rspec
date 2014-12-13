require "guard/rspec/inspectors/factory"
require "guard/rspec/command"
require "guard/rspec/notifier"

module Guard
  class RSpec < Plugin
    class Runner
      # NOTE: must match with const in RspecFormatter!
      TEMPORARY_FILE_PATH ||= "tmp/rspec_guard_result"

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
        Compat::UI.info(options[:message], reset: true)
        _run(true, paths, options)
      end

      def run(paths)
        paths = inspector.paths(paths)
        return true if paths.empty?
        Compat::UI.info("Running: #{paths.join(" ")}", reset: true)
        _run(false, paths, options)
      end

      def reload
        inspector.reload
      end

      private

      def _run(all, paths, options)
        return unless _cmd_option_present(options)
        command = Command.new(paths, options)

        _without_bundler_env { Kernel.system(command) }.tap do |success|
          _process_run_result(success, all)
        end
      end

      def _without_bundler_env
        if defined?(::Bundler)
          ::Bundler.with_clean_env { yield }
        else
          yield
        end
      end

      def _cmd_option_present(options)
        return true if options[:cmd]
        Compat::UI.error("No cmd option specified, unable to run specs!")
        notifier.notify_failure
        false
      end

      def _command_success?(success)
        return false if success.nil?
        [Command::FAILURE_EXIT_CODE, 0].include?($CHILD_STATUS.exitstatus)
      end

      def _command_output
        formatter_tmp_file = _tmp_file(options[:chdir])
        lines = File.readlines(formatter_tmp_file)
        summary = lines.first.strip
        failed_paths = lines[1..11].map(&:strip).compact

        [summary, failed_paths]
      rescue
        [nil, nil]
      ensure
        File.delete(formatter_tmp_file) if File.exists?(formatter_tmp_file)
      end

      def _open_launchy
        return unless options[:launchy]
        require "launchy"
        pn = Pathname.new(options[:launchy])
        ::Launchy.open(options[:launchy]) if pn.exist?
      end

      def _run_all_after_pass
        return unless options[:all_after_pass]
        run_all
      end

      def _process_run_result(result, all)
        unless _command_success?(result)
          notifier.notify_failure
          return
        end

        summary, failed_paths = _command_output
        unless summary && failed_paths
          notifier.notify_failure
        end

        inspector.failed(failed_paths)
        notifier.notify(summary)
        _open_launchy

        _run_all_after_pass if !all && result
      end

      def _tmp_file(chdir)
        chdir ? File.join(chdir, TEMPORARY_FILE_PATH) : TEMPORARY_FILE_PATH
      end
    end
  end
end
