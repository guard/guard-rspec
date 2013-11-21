require 'guard/rspec/inspectors/base_inspector.rb'

module Guard
  class RSpec
    module Inspectors
      # Inspector that remembers all failed paths and
      # returns that paths in future calls to #paths method
      class KeepingInspector < BaseInspector
        attr_accessor :failed_locations

        def initialize(options = {})
          super
          @failed_locations = []
        end

        def paths(paths)
          _clean(paths) | failed_locations
        end

        def failed(locations)
          @failed_locations = locations
        end

        def reload
          @failed_locations = []
        end
      end
    end
  end
end
