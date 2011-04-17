require 'guard'
require 'guard/guard'

module Guard
  class RSpec < Guard

    autoload :Runner,    'guard/rspec/runner'
    autoload :Inspector, 'guard/rspec/inspector'

    def initialize(watchers=[], options={})
      super
      @all_after_pass = options.delete(:all_after_pass)
      @all_on_start   = options.delete(:all_on_start)
      Runner.set_rspec_version(options)
    end

    # Call once when guard starts
    def start
      UI.info "Guard::RSpec is running, with RSpec #{Runner.rspec_version}!"
      run_all unless @all_on_start == false
    end

    def run_all
      @last_failed = !Runner.run(["spec"], options.merge(:message => "Running all specs"))
    end

    def run_on_change(paths)
      paths  = Inspector.clean(paths)
      passed = Runner.run(paths, options)

      if @all_after_pass == false
        passed
      else
        # run all the specs if the changed specs failed, like autotest
        if passed && @last_failed
          run_all
        else
          # track whether the changed specs failed for the next change
          @last_failed = !passed
        end
      end
    end

  end
end
