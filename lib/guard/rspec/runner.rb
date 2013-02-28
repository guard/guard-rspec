require 'drb/drb'
require 'rspec'

module Guard
  class RSpec
    class Runner

      FAILURE_EXIT_CODE = 2

      attr_accessor :options

      def initialize(options = {})
        @options = {
          :bundler      => true,
          :binstubs     => false,
          :rvm          => nil,
          :cli          => nil,
          :env          => nil,
          :notification => true,
          :spring       => false,
          :turnip       => false,
          :zeus         => false
        }.merge(options)

        unless ENV['SPEC_OPTS'].nil?
          UI.warning "The SPEC_OPTS environment variable is present. This can conflict with guard-rspec, particularly notifications."
        end

        deprecations_warnings
      end

      def run(paths, options = {})
        return false if paths.empty?

        message = options[:message] || "Running: #{paths.join(' ')}"
        UI.info(message, :reset => true)

        options = @options.merge(options)

        if drb_used?
          run_via_drb(paths, options)
        else
          run_via_shell(paths, options)
        end
      end

      def rspec_executable
        command = parallel? ? 'parallel_rspec' : 'rspec'
        @rspec_executable ||= (binstubs? && !executable_prefix?) ? "#{binstubs}/#{command}" : command
      end

      def failure_exit_code_supported?
        @failure_exit_code_supported ||= begin
          cmd_parts = []
          cmd_parts << "bundle exec" if bundle_exec?
          cmd_parts << rspec_executable
          cmd_parts << "--help"
          `#{cmd_parts.join(' ')}`.include? "--failure-exit-code"
        end
      end

      def parsed_or_default_formatter
        @parsed_or_default_formatter ||= begin
          # Use RSpec's parser to parse formatters
          formatters = ::RSpec::Core::ConfigurationOptions.new([]).parse_options()[:formatters]
          # Use a default formatter if none exists.
          # RSpec's parser returns an array in the format [[formatter, output], ...], so match their format
          formatters = [['progress']] if formatters.nil? || formatters.empty?
          # Construct a matching command line option, including output target
          formatters.map { |formatter| "-f #{formatter.join ' -o '}" }.join ' '
        end
      end

    private

      def environment_variables
        return if @options[:env].nil?
        "export " + @options[:env].map {|key, value| "#{key}=#{value}"}.join(' ') + ';'
      end

      def rspec_arguments(paths, options)
        arg_parts = []
        arg_parts << options[:cli]
        if @options[:notification]
          arg_parts << parsed_or_default_formatter unless options[:cli] =~ formatter_regex
          arg_parts << "-r #{File.dirname(__FILE__)}/formatter.rb"
          arg_parts << "-f Guard::RSpec::Formatter"
        end
        arg_parts << "--failure-exit-code #{FAILURE_EXIT_CODE}" if failure_exit_code_supported?
        arg_parts << "-r turnip/rspec" if @options[:turnip]
        arg_parts << paths.join(' ')

        arg_parts.compact.join(' ')
      end

      def parallel_rspec_arguments(paths, options)
        arg_parts = []
        arg_parts << options[:parallel_cli]
        if @options[:notification]
          arg_parts << parsed_or_default_formatter unless options[:cli] =~ formatter_regex
          arg_parts << "-r #{File.dirname(__FILE__)}/formatter.rb"
          arg_parts << "-f Guard::RSpec::Formatter"
        end
        arg_parts << "--failure-exit-code #{FAILURE_EXIT_CODE}" if failure_exit_code_supported?
        #arg_parts << "-r turnip/rspec" if @options[:turnip]
        arg_parts << paths.join(' ')

        arg_parts.compact.join(' ')
      end

      def rspec_command(paths, options)
        cmd_parts = []
        cmd_parts << environment_variables
        cmd_parts << "rvm #{@options[:rvm].join(',')} exec" if @options[:rvm].respond_to?(:join)
        cmd_parts << "bundle exec" if bundle_exec?
        cmd_parts << executable_prefix if executable_prefix?
        cmd_parts << rspec_executable
        cmd_parts << rspec_arguments(paths, options) if !parallel?
        cmd_parts << parallel_rspec_arguments(paths, options) if parallel?
        cmd_parts.compact.join(' ')
      end

      def run_via_shell(paths, options)
        success = system(rspec_command(paths, options))

        if @options[:notification] && !drb_used? && !success && rspec_command_exited_with_an_exception?
          Notifier.notify("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
        end

        success
      end

      def rspec_command_exited_with_an_exception?
        failure_exit_code_supported? && $?.exitstatus != FAILURE_EXIT_CODE
      end

      # We can optimize this path by hitting up the drb server directly, circumventing the overhead
      # of the user's shell, bundler and ruby environment.
      def run_via_drb(paths, options)
        require "shellwords"
        argv = rspec_arguments(paths, options).shellsplit

        # The user can specify --drb-port for rspec, we need to honor it.
        if idx = argv.index("--drb-port")
          port = argv[idx + 1].to_i
        end
        port = ENV["RSPEC_DRB"] || 8989 unless port && port > 0
        ret = drb_service(port.to_i).run(argv, $stderr, $stdout)

        [0, true].include?(ret)
      rescue DRb::DRbConnError
        # Fall back to the shell runner; we don't want to mangle the environment!
        run_via_shell(paths, options)
      end

      def drb_used?
        @drb_used ||= @options[:cli] && @options[:cli].include?('--drb')
      end

      # W we can avoid loading a large chunk of rspec
      # just to let DRb know what to do.
      #
      # For reference:
      #
      # * RSpec: https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/drb_command_line.rb
      def drb_service(port)
        require "drb/drb"

        # Make sure we have a listener running
        unless @drb_listener_running
          begin
            DRb.start_service("druby://localhost:0")
          rescue SocketError, Errno::EADDRNOTAVAIL
            DRb.start_service("druby://:0")
          end

          @drb_listener_running = true
        end

        @drb_services ||= {}
        @drb_services[port.to_i] ||= DRbObject.new_with_uri("druby://127.0.0.1:#{port}")
      end

      def bundler_allowed?
        @bundler_allowed ||= File.exist?("#{Dir.pwd}/Gemfile")
      end

      def bundler?
        @bundler ||= bundler_allowed? && @options[:bundler]
      end

      def binstubs?
        @binstubs ||= !!@options[:binstubs]
      end

      def executable_prefix?
        zeus? || spring?
      end

      def executable_prefix
        prefix = binstubs? ? "#{binstubs}/" : ''
        if zeus? && !parallel?
          prefix << 'zeus'
        elsif spring? && !parallel?
          prefix << 'spring'
        else
          prefix = nil
        end
        return prefix
      end

      def zeus?
        @options[:zeus] || false
      end

      def parallel?
        @options[:parallel] || false
      end

      def spring?
        @options[:spring] || false
      end

      def binstubs
        @options[:binstubs] == true ? "bin" : @options[:binstubs]
      end

      def bundle_exec?
        bundler? && !binstubs?
      end

      def deprecations_warnings
        [:color, :drb, [:fail_fast, "fail-fast"], [:formatter, "format"]].each do |option|
          key, value = option.is_a?(Array) ? option : [option, option.to_s]
          if @options.key?(key)
            @options.delete(key)
            UI.info %{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value}" to RSpec with the :cli option.}
          end
        end
        if @options.key?(:version)
            @options.delete(:version)
            UI.info %{DEPRECATION WARNING: The :version option is deprecated. Only RSpec 2 is now supported.}
        end
      end

      def formatter_regex
        @formatter_regex ||= /(?:^|\s)(?:-f\s*|--format(?:=|\s+))([\w:]+)/
      end
    end
  end
end
