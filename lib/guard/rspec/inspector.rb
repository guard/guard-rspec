module Guard
  class RSpec
    module Inspector
      class << self
        def excluded
          @excluded || []
        end

        def excluded=(glob)
          @excluded = Dir[glob.to_s]
        end

        def clean(paths)
          paths.uniq!
          paths.compact!
          clear_spec_files_list_after do
            paths = paths.select { |path| should_run_spec_file?(path) }
          end
          paths.reject { |p| included_in_other_path?(p, paths) }
        end

        private

        def should_run_spec_file?(path)
          (spec_file?(path) || spec_folder?(path)) && !excluded?(path)
        end

        def excluded?(path)
          excluded.include?(path)
        end

        def spec_file?(path)
          spec_files.include?(path)
        end

        def spec_folder?(path)
          path.match(%r{^spec[^\.]*$})
        end

        def spec_files
          @spec_files ||= Dir["spec/**/*_spec.rb"]
        end

        def clear_spec_files_list_after
          yield
          @spec_files = nil
        end

        def included_in_other_path?(path, paths)
          (paths - [path]).any? { |p| path.include?(p) && path.sub(p, '').include?('/') }
        end
      end
    end
  end
end
