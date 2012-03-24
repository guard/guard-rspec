module Guard
  class RSpec
    class Runner
      attr_reader :rspec_version

      def run(paths, options={})
        return false if paths.empty?
        message = options[:message] || "Running: #{paths.join(' ')}"
        UI.info(message, :reset => true)

        if options[:drb]
          result = run_drb_rspec(paths, options)
        else
          result = exec_rspec(paths, options)
        end

        if options[:notification] != false && !drb?(options) && failure_exit_code_supported?(options) && $? && !$?.success? && $?.exitstatus != failure_exit_code
          Notifier.notify("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
        end

        result
      end

      def exec_rspec(paths, options={})
        system(rspec_command(paths, options))

        $?.success?
      end

      def run_drb_rspec(paths, options={})
        require "rspec/core"

        args = rspec_arguments(paths, options)
        args << "--drb" unless args.include? "--drb"
        args.map! { |a| a.to_s }

        exit_code = ::RSpec::Core::Runner.run(args)

        # Successful?
        exit_code != failure_exit_code
      end

      def set_rspec_version(options={})
        @rspec_version = options[:version] || determine_rspec_version
      end

    private

      def rspec_arguments(paths, options={})
        args = []
        args += options[:args] if options[:args]
        args += ["-f", "progress"] if options[:cli].nil? || !options[:cli].split(/[\s=]/).any? { |w| %w[-f --format].include?(w) } || args.include?('-f') || args.include?('--format')

        if options[:notification] != false
          args += ["-r", "#{File.dirname(__FILE__)}/formatters/notification_#{rspec_class.downcase}.rb"]
          if rspec_version == 1
            args += ["-f", "Guard::RSpec::Formatter::Notification#{rspec_class}:/dev/null"]
          else
            args += ["-f", "Guard::RSpec::Formatter::Notification#{rspec_class}", "--out", "/dev/null"]
          end
        end

        args += ["--failure-exit-code", failure_exit_code] if failure_exit_code_supported?(options)
        args += paths

        args
      end

      def rspec_command(paths, options={})
        warn_deprectation(options)

        cmd_parts = []
        cmd_parts << "rvm #{options[:rvm].join(',')} exec" if options[:rvm].is_a?(Array)
        cmd_parts << "bundle exec" if (bundler? && options[:binstubs] == true && options[:bundler] != false) || (bundler? && options[:bundler] != false)
        cmd_parts << rspec_exec(options)
        cmd_parts << options[:cli] if options[:cli]
        cmd_parts += rspec_arguments(paths, options)

        cmd_parts.join(' ')
      end

      def drb?(options)
        !options[:cli].nil? && options[:cli].include?('--drb')
      end

      def bundler?
        @bundler ||= File.exist?("#{Dir.pwd}/Gemfile")
      end

      def failure_exit_code_supported?(options={})
        return @failure_exit_code_supported if defined?(@failure_exit_code_supported)
        @failure_exit_code_supported ||= begin
          cmd_parts = []
          cmd_parts << "bundle exec" if (bundler? && options[:bundler].is_a?(TrueClass)) || (bundler? && options[:binstubs].is_a?(TrueClass))
          ( saved = true; options[:binstubs] = false ) if options[:binstubs].is_a?(TrueClass) # failure exit code support is independent of rspec location
          cmd_parts << rspec_exec(options)
          options[:binstubs] = true if saved
          cmd_parts << "--help"
          `#{cmd_parts.join(' ')}`.include? "--failure-exit-code"
        end
      end

      def failure_exit_code
        2
      end

      def determine_rspec_version
        if File.exist?("#{Dir.pwd}/spec/spec_helper.rb")
          File.new("#{Dir.pwd}/spec/spec_helper.rb").read.include?("Spec::Runner") ? 1 : 2
        elsif bundler?
          # Allow RSpactor to be tested with RSpactor (bundle show inside a bundle exec)
          ENV['BUNDLE_GEMFILE'] = "#{Dir.pwd}/Gemfile"
          `bundle show rspec`.include?("/rspec-1.") ? 1 : 2
        else
          2
        end
      end

      def rspec_class
        case rspec_version
        when 1
          "Spec"
        when 2
          "RSpec"
        end
      end

      def rspec_exec(options = {})
        case rspec_version
        when 1
          options[:binstubs] == true && options[:bundler] != false ? "bin/spec" : "spec"
        when 2
          options[:binstubs] == true && options[:bundler] != false ? "bin/rspec" : "rspec"
        end
      end

      def warn_deprectation(options={})
        UI.info %{DEPRECATION WARNING: The :cli option is deprecated.  Please use an array via :args => ["-f", "nested", "--color", ...]} if options[:cli]

        [:color, :drb, :fail_fast, [:formatter, "format"]].each do |option|
          key, value = option.is_a?(Array) ? option : [option, option.to_s.gsub('_', '-')]
          if options.key?(key)
            UI.info %{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value}" to RSpec with the :args option.}
          end
        end
      end
    end
  end
end
