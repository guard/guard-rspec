module Guard
  class RSpec
    class Inspector

      def initialize(options = {})
        self.excluded   = options[:exclude]
        self.spec_paths = options[:spec_paths]
      end

      def excluded
        @excluded || []
      end

      def excluded=(pattern)
        @excluded = Dir[pattern.to_s]
      end

      def spec_paths
        @spec_paths || []
      end

      def spec_paths=(paths)
        @spec_paths = Array(paths)
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
        (spec_file?(path) || feature_file?(path) || spec_folder?(path)) && !excluded.include?(path)
      end

      def spec_file?(path)
        spec_files.include?(path)
      end

      def feature_file?(path)
        feature_files.include?(path)
      end

      def spec_folder?(path)
        path.match(%r{^(#{spec_paths.join("|")})[^\.]*$})
      end

      def spec_files
        @spec_files ||= spec_paths.collect { |path| Dir[File.join(path, "**{,/*/**}", "*_spec.rb")] }.flatten
      end

      def feature_files
        @feature_files ||= spec_paths.collect { |path| Dir[File.join(path, "**{,/*/**}", "*.feature")] }.flatten
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
