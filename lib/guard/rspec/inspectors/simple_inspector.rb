require 'guard/rspec/inspectors/base_inspector.rb'

module Guard
  class RSpec
    module Inspectors
      class SimpleInspector < BaseInspector
        def paths(ps)
          _clean(ps)
        end

        def failed(ps)
          # Don't care
        end

        def reload
          # Nothing to reload
        end
      end
    end
  end
end
