require 'guard'
require 'guard/guard'

module Guard
  class RSpec < Guard
    
    autoload :Runner, 'guard/rspec/runner'
    autoload :Inspector, 'guard/rspec/inspector'
    
    def initialize(watchers = [], options = {})
      super
      Runner.use_drb(options)
    end

    def start
      Runner.set_rspec_version(options)
    end
    
    def run_all
      Runner.run ["spec"], :message => "Running all specs"
    end
    
    def run_on_change(paths)
      paths = Inspector.clean(paths)
      Runner.run(paths) unless paths.empty?
    end
    
  end
end
