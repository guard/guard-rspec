require 'drb/drb'

module Guard
  class RSpec
    class Runner
      attr_reader :rspec_version

      FAILURE_EXIT_CODE = 2

      def initialize(options = {})
        @options = {
          :bundler      => true,
          :binstubs     => false,
          :rvm          => nil,
          :cli          => nil,
          :notification => true,
          :turnip       => false
        }.merge(options)

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

      def rspec_version
        @rspec_version ||= @options[:version] || determine_rspec_version
      end

      def rspec_executable
        @rspec_executable ||= begin
          exec = rspec_class.downcase
          binstubs? ? "#{binstubs}/#{exec}" : exec
        end
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

      def rspec_class
        @rspec_class ||= case rspec_version
                         when 1
                           "Spec"
                         when 2
                           "RSpec"
                         end
      end

      def parsed_or_default_formatter
        @parsed_or_default_formatter ||= begin
          file_name = "#{Dir.pwd}/.rspec"
          parsed_formatter = if File.exist?(file_name)
            formatters = File.read(file_name).scan(formatter_regex).flatten
            formatters.map { |formatter| "-f #{formatter}" }.join(' ')
          end

          parsed_formatter.nil? || parsed_formatter.empty? ? '-f progress' : parsed_formatter
        end
      end

    private

      def rspec_arguments(paths, options)
        arg_parts = []
        arg_parts << options[:cli]
        if @options[:notification]
          arg_parts << parsed_or_default_formatter unless options[:cli] =~ formatter_regex
          arg_parts << "-r #{File.dirname(__FILE__)}/formatters/notification_#{rspec_class.downcase}.rb"
          arg_parts << "-f Guard::RSpec::Formatter::Notification#{rspec_class}#{rspec_version == 1 ? ":" : " --out "}/dev/null"
        end
        arg_parts << "--failure-exit-code #{FAILURE_EXIT_CODE}" if failure_exit_code_supported?
        arg_parts << "-r turnip/rspec" if @options[:turnip]
        arg_parts << paths.join(' ')

        arg_parts.compact.join(' ')
      end

      def rspec_command(paths, options)
        cmd_parts = []
        cmd_parts << "rvm #{@options[:rvm].join(',')} exec" if @options[:rvm].respond_to?(:join)
        cmd_parts << "bundle exec" if bundle_exec?
        cmd_parts << rspec_executable
        cmd_parts << rspec_arguments(paths, options)
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
        if @drb_used.nil?
          @drb_used = @options[:cli] && @options[:cli].include?('--drb')
        else
          @drb_used
        end
      end

      # RSpec 1 & 2 use the same DRb call signature, and we can avoid loading a large chunk of rspec
      # just to let DRb know what to do.
      #
      # For reference:
      #
      # * RSpec 1: https://github.com/myronmarston/rspec-1/blob/master/lib/spec/runner/drb_command_line.rb
      # * RSpec 2: https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/drb_command_line.rb
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
        if @bundler_allowed.nil?
          @bundler_allowed = File.exist?("#{Dir.pwd}/Gemfile")
        else
          @bundler_allowed
        end
      end

      def bundler?
        if @bundler.nil?
          @bundler = bundler_allowed? && @options[:bundler]
        else
          @bundler
        end
      end

      def binstubs?
        if @binstubs.nil?
          @binstubs = !!@options[:binstubs]
        else
          @binstubs
        end
      end

      def binstubs
        if @options[:binstubs] == true
          "bin"
        else
          @options[:binstubs]
        end
      end

      def bundle_exec?
        bundler? && !binstubs?
      end

      def determine_rspec_version
        if File.exist?("#{Dir.pwd}/spec/spec_helper.rb")
          File.new("#{Dir.pwd}/spec/spec_helper.rb").read.include?("Spec::Runner") ? 1 : 2
        elsif bundler_allowed?
          ENV['BUNDLE_GEMFILE'] = "#{Dir.pwd}/Gemfile"
          `bundle show rspec`.include?("/rspec-1.") ? 1 : 2
        else
          2
        end
      end

      def deprecations_warnings
        [:color, :drb, [:fail_fast, "fail-fast"], [:formatter, "format"]].each do |option|
          key, value = option.is_a?(Array) ? option : [option, option.to_s]
          if @options.key?(key)
            @options.delete(key)
            UI.info %{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value}" to RSpec with the :cli option.}
          end
        end
      end

      def formatter_regex
        @formatter_regex ||= /(?:^|\s)(?:-f\s*|--format(?:=|\s+))([\w:]+)/
      end

    end
  end
end
