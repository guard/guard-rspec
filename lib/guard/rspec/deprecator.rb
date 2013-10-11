module Guard
  class RSpec
    class Deprecator
      attr_accessor :options

      def self.warns_about_deprecated_options(options = {})
        new(options).warns_about_deprecated_options
      end

      def initialize(options = {})
        @options = options
      end

      def warns_about_deprecated_options
        _spec_opts_env
        _version_option
        _exclude_option
        _use_cmd_option
      end

      private

      def _spec_opts_env
        return if ENV['SPEC_OPTS'].nil?
        UI.warning "The SPEC_OPTS environment variable is present. This can conflict with guard-rspec, particularly notifications."
      end

      def _version_option
        return unless options.key?(:version)
        _deprectated('The :version option is deprecated. Only RSpec ~> 2.14 is now supported.')
      end

      def _exclude_option
        return unless options.key?(:exclude)
        _deprectated('The :exclude option is deprecated. Please Guard ignore method instead. https://github.com/guard/guard#ignore')
      end

      def _use_cmd_option
        %w[color drb fail_fast formatter env bundler binstubs rvm cli spring turnip zeus foreman].each do |option|
          next unless options.key?(option.to_sym)
          _deprectated("The :#{option} option is deprecated. Please customize the new :cmd option to fit your need.")
        end
      end

      def _deprectated(message)
        UI.warning %{Guard::RSpec DEPRECATION WARNING: #{message}}
      end

    end
  end
end
