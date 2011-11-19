module Guard
  class RSpec
    module Runner
      class << self
        attr_reader :rspec_version

        def run(paths, options={})
          return false if paths.empty?
          message = options[:message] || "Running: #{paths.join(' ')}"
          UI.info(message, :reset => true)
          system(rspec_command(paths, options))

          if options[:notification] != false && !drb?(options) && failure_exit_code_supported?(options) && $? && !$?.success? && $?.exitstatus != failure_exit_code
            Notifier.notify("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
          end

          $?.success?
        end

        def set_rspec_version(options={})
          @rspec_version = options[:version] || determine_rspec_version
        end

      private

        def rspec_command(paths, options={})
          warn_deprectation(options)

          cmd_parts = []
          cmd_parts << "rvm #{options[:rvm].join(',')} exec" if options[:rvm].is_a?(Array)
          cmd_parts << "bundle exec" if bundler? && options[:bundler] != false
          cmd_parts << rspec_exec.downcase
          cmd_parts << options[:cli] if options[:cli]
          cmd_parts << "-f progress" if options[:cli].nil? || !options[:cli].split(' ').any? { |w| %w[-f --format].include?(w) }
          cmd_parts << "-r #{File.dirname(__FILE__)}/formatters/notification_#{rspec_exec.downcase}.rb -f Guard::RSpec::Formatter::Notification#{rspec_exec}#{rspec_version == 1 ? ":" : " --out "}/dev/null" if options[:notification] != false
          cmd_parts << "--failure-exit-code #{failure_exit_code}" if failure_exit_code_supported?(options)
          cmd_parts << paths.join(' ')

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
            cmd_parts << "bundle exec" if bundler? && options[:bundler] != false
            cmd_parts << rspec_exec.downcase
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

        def rspec_exec
          case rspec_version
          when 1
            "Spec"
          when 2
            "RSpec"
          end
        end

        def warn_deprectation(options={})
          [:color, :drb, :fail_fast, [:formatter, "format"]].each do |option|
            key, value = option.is_a?(Array) ? option : [option, option.to_s.gsub('_', '-')]
            if options.key?(key)
              UI.info %{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value}" to RSpec with the :cli option.}
            end
          end
        end

      end
    end
  end
end
