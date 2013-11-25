require 'guard/rspec/inspectors/base_inspector.rb'

module Guard
  class RSpec
    module Inspectors
      # Inspector that remembers all failed paths and
      # returns that paths in future calls to #paths method
      # along with any new paths passed as parameter to #paths
      class KeepingInspector < BaseInspector
        attr_accessor :failed_locations

        def initialize(options = {})
          super
          @failed_locations = []
        end

        def paths(paths)
          _with_failed_locations(_clean(paths))
        end

        def failed(locations)
          @failed_locations = locations
        end

        def reload
          @failed_locations = []
        end

        private

        # Return paths + failed locations.
        # Do not include location in result if its path is already included.
        def _with_failed_locations(paths)
          locations = failed_locations.select { |l| !paths.include?(_location_path(l)) }
          paths | locations
        end

        # Extract file path from location
        def _location_path(location)
          location.match(/^(\.\/)?(.*?)(:\d+)?$/)[2]
        end
      end
    end
  end
end
