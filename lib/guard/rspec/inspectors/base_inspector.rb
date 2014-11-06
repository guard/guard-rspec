module Guard
  class RSpec < Plugin
    module Inspectors
      class BaseInspector
        attr_accessor :options, :spec_paths

        def initialize(options = {})
          @options = options
          @spec_paths = @options[:spec_paths]
          @chdir = @options[:chdir]
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
          (spec_dirs + spec_files).uniq
        end

        def _select_only_spec_dirs(paths)
          paths.select do |path|
            File.directory?(path) ||
              _spec_paths_with_chdir.include?(path)
          end
        end

        def _select_only_spec_files(paths)
          spec_files = _collect_files("*[_.]spec.rb")
          feature_files = _collect_files("*.feature")
          files = (spec_files + feature_files).flatten

          paths.select do |path|
            files.any? do |file|
              file == Formatter.path_with_chdir(path, @chdir)
            end
          end
        end

        def _spec_paths_with_chdir
          Formatter.paths_with_chdir(spec_paths, @chdir)
        end

        def _collect_files(pattern)
          _spec_paths_with_chdir.collect do |path|
            Dir[File.join(path, "**{,/*/**}", pattern)]
          end
        end
      end
    end
  end
end
