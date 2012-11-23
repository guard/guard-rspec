require 'guard'
require 'guard/guard'

module Guard
  class RSpec < Guard
    autoload :Runner,    'guard/rspec/runner'
    autoload :Inspector, 'guard/rspec/inspector'

    attr_accessor :last_failed, :failed_paths

    def initialize(watchers = [], options = {})
      super
      @options = {
        :focus_on_failed => false,
        :all_after_pass => true,
        :all_on_start   => true,
        :keep_failed    => true,
        :spec_paths     => ["spec"],
        :run_all        => {}
      }.merge(options)
      @last_failed  = false
      @failed_paths = []

      @inspector = Inspector.new(@options)
      @runner    = Runner.new(@options)
    end

    # Call once when guard starts
    def start
      UI.info "Guard::RSpec is running"
      run_all if @options[:all_on_start]
    end

    def run_all
      passed = @runner.run(@inspector.spec_paths, @options[:run_all].merge(:message => 'Running all specs'))

      unless @last_failed = !passed
        @failed_paths = []
      else
        throw :task_has_failed
      end
    end

    def reload
      @failed_paths = []
    end

    def run_on_changes(paths)

      if @last_failed && @options[:focus_on_failed]
        path = './tmp/rspec_guard_result'
        if File.exist?(path)
          paths = File.open(path) { |file| file.read.split("\n") }
          File.delete(path)

          # some sane limit, stuff will explode if all tests fail ... cap at 10
          paths = paths[0..10]
        end
      else
        paths += failed_paths if @options[:keep_failed]
        paths  = @inspector.clean(paths)
      end

      if passed = @runner.run(paths)
        remove_failed(paths)

        # run all the specs if the run before this one failed
        if last_failed && @options[:all_after_pass]
          @last_failed = false
          run_all
        end
      else
        @last_failed = true
        add_failed(paths)

        throw :task_has_failed
      end
    end

  private

    def run(paths)
    end

    def remove_failed(paths)
      @failed_paths -= paths if @options[:keep_failed]
    end

    def add_failed(paths)
      @failed_paths += paths if @options[:keep_failed]
    end

  end
end

