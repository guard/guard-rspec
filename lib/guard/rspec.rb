require 'guard'
require 'guard/guard'

module Guard
  class RSpec < Guard
    
    autoload :Runner, 'guard/rspec/runner'
    autoload :Inspector, 'guard/rspec/inspector'
    
    def initialize(watchers = [], options = {})
      super
      Runner.set_rspec_version(options)
    end
    
    def run_all
      Runner.run ["spec"], options.merge(:message => "Running all specs")
    end
    
    def run_on_change(paths)
      paths = Inspector.clean(paths)
      Runner.run(paths, options) unless paths.empty?
    end
    
  end
end
