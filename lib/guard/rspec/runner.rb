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
          :notification => true
        }.merge(options)

        deprecations_warnings
      end

      def run(paths, options = {})
        return false if paths.empty?

        message = options[:message] || "Running: #{paths.join(' ')}"
        UI.info(message, :reset => true)

        success = system(rspec_command(paths, @options.merge(options)))

        if @options[:notification] && !drb_used? && !success && rspec_command_exited_with_an_exception?
          Notifier.notify("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
        end

        success
      end

      def rspec_version
        @rspec_version ||= @options[:version] || determine_rspec_version
      end

      def rspec_exec
        @rspec_exec ||= begin
          exec = rspec_class.downcase
          binstubs? ? "bin/#{exec}" : exec
        end
      end

      def failure_exit_code_supported?
        @failure_exit_code_supported ||= begin
          cmd_parts = []
          cmd_parts << "bundle exec" if bundler?
          cmd_parts << rspec_exec
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

    private

      def rspec_command(paths, options)
        cmd_parts = []
        cmd_parts << "rvm #{@options[:rvm].join(',')} exec" if @options[:rvm].respond_to?(:join)
        cmd_parts << "bundle exec" if bundler?
        cmd_parts << rspec_exec << options[:cli]
        cmd_parts << "-f progress" if !options[:cli] || options[:cli].split(/[\s=]/).none? { |w| %w[-f --format].include?(w) }
        if @options[:notification]
          cmd_parts << "-r #{File.dirname(__FILE__)}/formatters/notification_#{rspec_class.downcase}.rb"
          cmd_parts << "-f Guard::RSpec::Formatter::Notification#{rspec_class}#{rspec_version == 1 ? ":" : " --out "}/dev/null"
        end
        cmd_parts << "--failure-exit-code #{FAILURE_EXIT_CODE}" if failure_exit_code_supported?
        cmd_parts << paths.join(' ')

        cmd_parts.compact.join(' ')
      end

      def rspec_command_exited_with_an_exception?
        failure_exit_code_supported? && $?.exitstatus != FAILURE_EXIT_CODE
      end

      def drb_used?
        if @drb_used.nil?
          @drb_used = @options[:cli] && @options[:cli].include?('--drb')
        else
          @drb_used
        end
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
          @binstubs = bundler? && @options[:binstubs]
        else
          @binstubs
        end
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

    end
  end
end
