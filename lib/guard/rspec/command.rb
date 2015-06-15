require "rspec/core"
require "pathname"

require "guard/rspec"

module Guard
  class RSpec < Plugin
    class Command < String
      FAILURE_EXIT_CODE = 2

      attr_accessor :paths, :options

      def initialize(paths, options = {})
        @paths = paths
        @options = options
        super(_parts.join(" "))
      end

      private

      def _parts
        parts = _parts_begin
        parts << _visual_formatter
        parts << _guard_formatter
        parts << "--failure-exit-code #{FAILURE_EXIT_CODE}"
        parts << options[:cmd_additional_args] || ""
        parts << _parts_end
      end

      def _parts_begin
        if parallel?
          [
            "bundle exec parallel_rspec",
            options[:parallel_cli],
            "-o '"
          ].compact
        else
          [options[:cmd]]
        end
      end

      def _parts_end
        if parallel?
          "' spec"
        else
          _paths(options).join(" ")
        end
      end

      def parallel?
        options[:parallel] || false
      end

      def _paths(options)
        return paths unless chdir = options[:chdir]
        paths.map { |path| path.sub(File.join(chdir, "/"), "") }
      end

      def _visual_formatter
        return if _cmd_include_formatter?
        _rspec_formatters || "-f progress"
      end

      def _rspec_formatters
        # RSpec::Core::ConfigurationOptions#parse_options method was renamed to
        # #options in rspec-core v3.0.0.beta2 so call the first one if
        # available. Fixes #249
        config = ::RSpec::Core::ConfigurationOptions.new([])
        config.parse_options if config.respond_to?(:parse_options)
        formatters = config.options[:formatters] || nil

        # RSpec's parser returns an array in the format
        #
        # [[formatter, output], ...],
        #
        # so match their format Construct a matching command line option,
        # including output target

        return formatters unless formatters
        formatters.map { |entries| "-f #{entries.join ' -o '}" }.join(" ")
      end

      def _cmd_include_formatter?
        options[:cmd] =~ /(?:^|\s)(?:-f\s*|--format(?:=|\s+))([\w:]+)/
      end

      def _guard_formatter
        dir = Pathname.new(__FILE__).dirname.dirname
        "-r #{dir + 'rspec_formatter.rb'} -f Guard::RSpecFormatter"
      end
    end
  end
end
