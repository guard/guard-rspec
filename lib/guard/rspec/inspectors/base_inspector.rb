require "guard/rspec"

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

        def paths(_paths)
          fail _abstract
        end

        def failed(_locations)
          fail _abstract
        end

        def reload
          fail _abstract
        end

        private

        def _abstract
          "Must be implemented in subclass"
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
          chdir_paths = _spec_paths_with_chdir
          paths.select do |path|
            File.directory?(path) ||
              chdir_paths.include?(path)
          end
        end

        def _select_only_spec_files(paths)
          files = _collect_files.flatten

          paths.select do |path|
            files.any? do |file|
              file == Formatter.path_with_chdir(path, @chdir)
            end
          end
        end

        def _spec_paths_with_chdir
          Formatter.paths_with_chdir(spec_paths, @chdir)
        end

        def _collect_files
          _spec_paths_with_chdir.map do |path|
            # TODO: not tested properly
            Dir[File.join(path, ::RSpec.configuration.pattern)]
          end
        end
      end
    end
  end
end
