require 'guard'
require 'guard/plugin'

module Guard
  class RSpec < Plugin
    require 'guard/rspec/options'
    require 'guard/rspec/deprecator'
    require 'guard/rspec/runner'

    attr_accessor :options, :runner

    def initialize(options = {})
      super
      @options = Options.with_defaults(options)
      Deprecator.warns_about_deprecated_options(@options)
      @runner = Runner.new(@options)
    end

    def start
      ::Guard::UI.info 'Guard::RSpec is running'
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

