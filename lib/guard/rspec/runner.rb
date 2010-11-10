module Guard
  class RSpec
    module Runner
      class << self
        attr_reader :rspec_version
        
        def run(paths, options = {})
          message = options[:message] || "Running: #{paths.join(' ')}"
          UI.info message, :reset => true
          system(rspec_command(paths, options))
        end
        
        def set_rspec_version(options = {})
          @rspec_version = options[:version] || determine_rspec_version
        end
        
      private
        
        def rspec_command(paths, options = {})
          cmd_parts = []
          cmd_parts << "rvm #{options[:rvm].join(',')} exec" if options[:rvm].is_a?(Array)
          cmd_parts << "bundle exec" if bundler? && options[:bundler] != false
          
          formatter = options[:formatter] || "default"
          case rspec_version
          when 1
            cmd_parts << "spec"
            cmd_parts << "--require #{File.dirname(__FILE__)}/formatters/#{formatter}_spec.rb --format #{formatter.capitalize}Spec"
          when 2
            cmd_parts << "rspec"
            cmd_parts << "--require #{File.dirname(__FILE__)}/formatters/#{formatter}_rspec.rb --format #{formatter.capitalize}RSpec"
          end
          
          cmd_parts << "--drb" if options[:drb] == true
          cmd_parts << "--color" if options[:color] != false
          cmd_parts << "--fail-fast" if options[:fail_fast] == true
          
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
