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
        :keep_failed    => true,
        :spec_paths     => ["spec"]
      }.update(options)
      @last_failed  = false
      @failed_paths = []

      @runner = Runner.new
      @inspector = Inspector.new

      @runner.set_rspec_version(options)
      @inspector.excluded = @options[:exclude]
      @inspector.spec_paths = @options[:spec_paths]
    end

    # Call once when guard starts
    def start
      UI.info "Guard::RSpec is running, with RSpec #{@runner.rspec_version}!"
      run_all if @options[:all_on_start]
    end

    def run_all
      passed = @runner.run(options[:spec_paths], options.merge(options[:run_all] || {}).merge(:message => "Running all specs"))

      @last_failed = !passed
      if passed
        @failed_paths = []
      else
        throw :task_has_failed
      end
    end

    def reload
      @failed_paths = []
    end

    def run_on_change(paths)
      paths += @failed_paths if @options[:keep_failed]
      paths  = @inspector.clean(paths)
      passed = @runner.run(paths, options)

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
        throw :task_has_failed
      end
    end

  end
end

