module Guard
  class RSpec
    module Runner
      class << self
        attr_reader :rspec_version

        def run(paths, options = {})
          message = options[:message] || "Running: #{paths.join(' ')}"
          UI.info message, :reset => true
          system(rspec_command(paths))
        end

        def set_rspec_version(options = {})
          @rspec_version = options[:version] || determine_rspec_version
        end

        def use_drb(options = {})
          @use_drb = options[:drb] == true
        end

        def using_drb?
          @use_drb
        end

      private

        def rspec_command(paths)
          cmd_parts = []
          cmd_parts << "bundle exec" if bundler?

          case rspec_version
          when 1
            cmd_parts << "spec"
            cmd_parts << "-f progress --require #{File.dirname(__FILE__)}/formatters/spec_notify.rb --format SpecNotify:STDOUT"
          when 2
            cmd_parts << "rspec"
            cmd_parts << "--require #{File.dirname(__FILE__)}/formatters/rspec_notify.rb --format RSpecNotify"
          end

          cmd_parts << "--drb" if using_drb?
          cmd_parts << "--color"

          cmd_parts << paths.join(' ')
          cmd_parts.join(" ")
        end

        def bundler?
          @bundler ||= File.exist?("#{Dir.pwd}/Gemfile")
        end

        def determine_rspec_version
          UI.info "Determine rspec_version... (can be forced with Guard::RSpec version option)"
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

      end
    end
  end
end
