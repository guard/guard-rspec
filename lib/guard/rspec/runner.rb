require "guard/rspec/inspectors/factory"
require "guard/rspec/command"
require "guard/rspec/notifier"
require "guard/rspec/results"

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
        Compat::UI.info("Running: #{paths.join(' ')}", reset: true)
        _run(false, paths, options)
      end

      def reload
        inspector.reload
      end

      private

      def _run(all, paths, options)
        return unless _cmd_option_present(options)
        command = Command.new(paths, options)

        _without_bundler_env { Kernel.system(command) }.tap do |result|
          if _command_success?(result)
            _process_run_result(result, all)
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
        Results.new(formatter_tmp_file)
      ensure
        File.delete(formatter_tmp_file) if File.exist?(formatter_tmp_file)
      end

      def _open_launchy
        return unless options[:launchy]
        require "launchy"
        pn = Pathname.new(options[:launchy])
        ::Launchy.open(options[:launchy]) if pn.exist?
      end

      def _open_emacs(failed_paths)
        return unless options[:emacs]
        pn = Pathname.new(options[:emacs])
        elisp = <<-"EOS".gsub(/\s+/, " ").strip
        (display-buffer
         (save-excursion
          (with-current-buffer (find-file-noselect \"#{pn}\" t)
           (revert-buffer t t)
           (ansi-color-apply-on-region (point-min)(point-max))
           (set-buffer-modified-p nil)
           (compilation-mode t)
           (current-buffer))))
        EOS
        IO.popen(["emacsclient", "--eval", elisp]) do |p|
          p.readlines
          p.close
        end if pn.exist? && !failed_paths.empty?
      end

      def _run_all_after_pass
        return unless options[:all_after_pass]
        run_all
      end

      def _process_run_result(result, all)
        results = _command_output
        inspector.failed(results.failed_paths)
        notifier.notify(results.summary)
        _open_launchy
        _open_emacs(failed_paths)

        _run_all_after_pass if !all && result
      end

      def _tmp_file(chdir)
        chdir ? File.join(chdir, TEMPORARY_FILE_PATH) : TEMPORARY_FILE_PATH
      end
    end
  end
end
