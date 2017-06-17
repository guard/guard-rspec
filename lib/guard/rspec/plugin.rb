module Guard
  module RSpec
    class Plugin
      include Compat::API

      attr_accessor :runner

      def initialize(opts = {})
        super
        @options = Options.with_defaults(opts)
        Deprecator.warns_about_deprecated_options(options)
        @runner = Runner.new(options)
      end

      def start
        Compat::UI.info "Guard::RSpec is running"
        run_all if options[:all_on_start]
      end

      def run_all
        _throw_if_failed { runner.run_all }
      end

      def reload
        runner.reload
      end

      def run_on_modifications(paths)
        return false if paths.empty?
        _throw_if_failed { runner.run(paths) }
      end

      private

      def _throw_if_failed
        throw :task_has_failed unless yield
      end
    end
  end
end
