require 'guard/rspec/inspectors/base_inspector.rb'

module Guard
  class RSpec
    module Inspectors
      # Inspector that remembers all failed paths and
      # returns that paths in future calls to #paths method
      class KeepingInspector < BaseInspector
        attr_accessor :failed_paths

        def initialize(options = {})
          super
          @failed_paths = []
        end

        def paths(ps)
          _clean(failed_paths + ps)
        end

        def failed(ps)
          @failed_paths = ps
        end

        def reload
          @failed_paths = []
        end
      end
    end
  end
end
