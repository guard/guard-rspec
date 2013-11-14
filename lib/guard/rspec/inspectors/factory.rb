require 'guard/rspec/inspectors/simple_inspector.rb'
require 'guard/rspec/inspectors/keeping_inspector.rb'
require 'guard/rspec/inspectors/focused_inspector.rb'

module Guard
  class RSpec
    module Inspectors
      class Factory
        class << self
          def create(options = {})
            if options[:focus_on_failed]
              FocusedInspector.new(options)
            elsif options[:keep_failed]
              KeepingInspector.new(options)
            else
              SimpleInspector.new(options)
            end
          end

          private :new
        end
      end
    end
  end
end

