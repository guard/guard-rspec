module Guard
  class RSpec
    module Inspectors
      class BaseInspector
        attr_accessor :options, :spec_paths

        def initialize(options = {})
          @options = options
          @spec_paths = @options[:spec_paths]
        end

        def paths(paths)
          raise _abstract
        end

        def failed(locations)
          raise _abstract
        end

        def reload
          raise _abstract
        end

        private

        def _abstract
          'Must be implemented in subclass'
        end

        # Leave only spec/feature files from spec_paths, remove others
        def _clean(paths)
          paths.uniq!
          paths.compact!
          spec_dirs = _select_only_spec_dirs(paths)
          spec_files = _select_only_spec_files(paths)
          spec_dirs + spec_files
        end

        def _select_only_spec_dirs(paths)
          paths.select { |p| File.directory?(p) || spec_paths.include?(p) }
        end

        def _select_only_spec_files(paths)
          spec_files = spec_paths.collect { |path| Dir[File.join(path, "**{,/*/**}", "*[_.]spec.rb")] }
          feature_files = spec_paths.collect { |path| Dir[File.join(path, "**{,/*/**}", "*.feature")] }
          files = (spec_files + feature_files).flatten
          paths.select { |p| files.include?(p) }
        end
      end
    end
  end
end
