require 'guard/rspec/inspectors/base_inspector.rb'

module Guard
  class RSpec
    module Inspectors
      class SimpleInspector < BaseInspector
        def paths(paths)
          _clean(paths)
        end

        def failed(locations)
          # Don't care
        end

        def reload
          # Nothing to reload
        end
      end
    end
  end
end
