module Guard
  class RSpec
    class Deprecator

      def self.deprecated_options(options = {})

            unless ENV['SPEC_OPTS'].nil?
              UI.warning "The SPEC_OPTS environment variable is present. This can conflict with guard-rspec, particularly notifications."
            end

          # :bundler      => true,
          # :binstubs     => false,
          # :rvm          => nil,
          # :cli          => nil,
          # :env          => nil,
          # :launchy      => nil,
          # notification: true,
          # :spring       => false,
          # :turnip       => false,
          # :zeus         => false,
          # :foreman      => false


          # def deprecations_warnings
          #   [:color, :drb, [:fail_fast, "fail-fast"], [:formatter, "format"]].each do |option|
          #     key, value = option.is_a?(Array) ? option : [option, option.to_s]
          #     if options.key?(key)
          #       @options.delete(key)
          #       UI.info %{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value}" to RSpec with the :cli option.}
          #     end
          #   end
          #   if options.key?(:version)
          #     @options.delete(:version)
          #     UI.info %{DEPRECATION WARNING: The :version option is deprecated. Only RSpec 2 is now supported.}
          #   end
          # end
      end
    end
  end
end
