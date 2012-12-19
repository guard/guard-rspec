require 'guard'
require 'guard/guard'

module Guard
  class RSpec < Guard
    autoload :Runner,    'guard/rspec/runner'
    autoload :Inspector, 'guard/rspec/inspector'

    attr_accessor :last_failed, :failed_paths, :runner, :inspector

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

      original_paths = paths.dup

      focused = false
      if last_failed && @options[:focus_on_failed]
        path = './tmp/rspec_guard_result'
        if File.exist?(path)
          single_spec = paths && paths.length == 1 && paths[0].include?("_spec") ? paths[0] : nil
          failed_specs = File.open(path) { |file| file.read.split("\n") }

          File.delete(path)

          if single_spec && @inspector.clean([single_spec]).length == 1
            failed_specs = failed_specs.select{|p| p.include? single_spec}
          end
          
          if failed_specs.any?
            # some sane limit, stuff will explode if all tests fail 
            #   ... cap at 10

            paths = failed_specs[0..10]
            focused = true
          end

          # switch focus to the single spec
          if single_spec and failed_specs.length > 0
            focused = true
          end
        end
      end

      if focused
        add_failed(original_paths)
        add_failed(paths.map{|p| p.split(":")[0]})
      else
        paths += failed_paths if @options[:keep_failed]
        paths  = @inspector.clean(paths).uniq
      end

      if passed = @runner.run(paths)
        unless focused
          remove_failed(paths)
        end

        if last_failed && focused
          run_on_changes(failed_paths)
        # run all the specs if the run before this one failed
        elsif last_failed && @options[:all_after_pass]
          @last_failed = false
          run_all
        end
      else
        @last_failed = true
        unless focused
          add_failed(paths)
        end

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
      if @options[:keep_failed]
        @failed_paths += paths 
        @failed_paths.uniq!
      end
    end

  end
end

