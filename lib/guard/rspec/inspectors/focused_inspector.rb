require 'guard/rspec/inspectors/base_inspector.rb'

module Guard
  class RSpec
    module Inspectors
      # Inspector that focuses on set of paths if any of them is failing.
      # Returns only that set of paths on all future calls to #paths
      # until they all pass
      class FocusedInspector < BaseInspector
        attr_accessor :focused_paths

        def initialize(options = {})
          super
          @focused_paths = []
        end

        def paths(ps)
          if focused_paths.any?
            focused_paths
          else
            _clean(ps)
          end
        end

        def failed(ps)
          if ps.empty?
            @focused_paths = []
          else
            @focused_paths = ps if focused_paths.empty?
          end
        end

        def reload
          @focused_paths = []
        end
      end
    end
  end
end
