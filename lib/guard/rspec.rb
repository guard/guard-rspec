require 'guard'
require 'guard/guard'

module Guard
  class RSpec < Guard
    autoload :Runner,    'guard/rspec/runner'
    autoload :Inspector, 'guard/rspec/inspector'

    def initialize(watchers=[], options={})
      super
      @options = {
        :all_after_pass => true,
        :all_on_start   => true,
        :keep_failed    => true
      }.update(options)
      @last_failed  = false
      @failed_paths = []

      Runner.set_rspec_version(options)
    end

    # Call once when guard starts
    def start
      UI.info "Guard::RSpec is running, with RSpec #{Runner.rspec_version}!"
      run_all if @options[:all_on_start]
    end

    def run_all
      passed = Runner.run(["spec"], options.merge(:message => "Running all specs"))

      @failed_paths = [] if passed
      @last_failed  = !passed
    end

    def run_on_change(paths)
      paths  = Inspector.clean(paths)
      paths += @failed_paths if @options[:keep_failed]
      passed = Runner.run(paths.uniq, options)

      if passed
        # clean failed paths memory
        @failed_paths -= paths if @options[:keep_failed]
        # run all the specs if the changed specs failed, like autotest
        run_all if @last_failed && @options[:all_after_pass]
      else
        # remember failed paths for the next change
        @failed_paths += paths if @options[:keep_failed]
        # track whether the changed specs failed for the next change
        @last_failed = true
      end
    end

  end
end
