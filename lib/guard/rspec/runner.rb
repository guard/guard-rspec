require 'guard/rspec/command'
require 'guard/rspec/inspector'

module Guard
  class RSpec
    class Runner
      attr_accessor :options, :inspector

      def initialize(options = {})
        @options = {
          all_after_pass: false,
          notification:   true,
          run_all:        { message: 'Running all specs' },
          launchy:        nil
        }.merge(options)

        @inspector = Inspector.new(@options)
      end

      def run_all
        options = @options.merge(@options[:run_all])
        ::Guard::UI.info(options[:message], reset: true)

        _run(inspector.paths, [], options)
      end

      def run(paths)
        failed_paths = inspector.failed_paths
        paths = inspector.paths(paths)
        return if paths.empty?

        ::Guard::UI.info("Running: #{paths.join(' ')}", reset: true)

        _run(paths, failed_paths, options)
      end

      def reload
        inspector.clear_paths
      end

      private

      def _run(paths, failed_paths, options)
        command = Command.new(paths, options)
        _without_bundler_env { Kernel.system(command) }.tap do |success|
          success ? inspector.clear_paths(paths) : _notify_failure
          _open_launchy
          _run_all_after_pass(success, failed_paths)
        end
      end

      def _without_bundler_env
        if defined?(::Bundler)
          ::Bundler.with_clean_env { yield }
        else
          yield
        end
      end

      def _notify_failure
        return unless options[:notification]
        return unless command_exception?
        ::Guard::Notifier.notify('Failed', title: 'RSpec results', image: :failed, priority: 2)
      end

      def command_exception?
        $?.exitstatus != Command::FAILURE_EXIT_CODE
      end

      def _open_launchy
        return unless options[:launchy]
        require 'launchy'
        pn = Pathname.new(options[:launchy])
        ::Launchy.open(options[:launchy]) if pn.exist?
      end

      def _run_all_after_pass(success, failed_paths)
        return unless options[:all_after_pass]
        run_all if success && !failed_paths.empty?
      end

    end
  end
end
