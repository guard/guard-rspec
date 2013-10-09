module Guard
  class RSpec
    class Inspector
      FOCUSED_FILE_PATH = './tmp/rspec_guard_result'

      attr_accessor :options, :failed_paths, :spec_paths

      def initialize(options = {})
        @options = {
          focus_on_failed: true,
          keep_failed:     false,
          exclude:         "[]",
          spec_paths:      %w[spec]
        }.merge(options)

        @failed_paths = []
        @spec_paths = @options[:spec_paths]
      end

      def paths(paths = nil)
        if paths
          _paths(paths)
        else
          spec_paths
        end
      end

      def clear_paths(paths = nil)
        if paths
          @failed_paths -= paths
        else
          @failed_paths.clear
        end
      end

      private

      def _paths(paths)
        _focused_paths || if options[:keep_failed]
          @failed_paths += _clean(paths)
        else
          _clean(paths)
        end
      end

      def _focused_paths
        return nil unless options[:focus_on_failed]
        File.open(FOCUSED_FILE_PATH).read.split("\n")[0..10]
      rescue
        nil
      ensure
        File.exist?(FOCUSED_FILE_PATH) && File.delete(FOCUSED_FILE_PATH)
      end

      def _clean(paths)
        paths.uniq!
        paths.compact!
        paths.select! { |p| _spec_file?(p) || _feature_file?(p) }
        paths.reject! { |p| _excluded?(p) }
        paths
      end

      def _spec_file?(path)
        @spec_files ||= spec_paths.collect { |path| Dir[File.join(path, "**{,/*/**}", "*[_.]spec.rb")] }.flatten
        @spec_files.include?(path)
      end

      def _feature_file?(path)
        @feature_files ||= spec_paths.collect { |path| Dir[File.join(path, "**{,/*/**}", "*.feature")] }.flatten
        @feature_files.include?(path)
      end

      def _excluded?(path)
        Dir[options[:exclude]].include?(path)
      end
    end
  end
end
