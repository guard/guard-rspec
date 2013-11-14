module Guard
  class RSpec
    module Options
      DEFAULTS = {
          # Common
          all_on_start: false,

          # Runner specific
          all_after_pass: false,
          run_all:        { message: 'Running all specs' },
          launchy:        nil,

          # Command & Inspector specific
          focus_on_failed: true,
          cmd:             'rspec',
          keep_failed:     false,
          spec_paths:      %w[spec]
      }.freeze

      class << self
        def with_defaults(options = {})
          _deep_merge(DEFAULTS, options)
        end

        private

        def _deep_merge(hash1, hash2)
          hash1.merge(hash2) do |key, oldval, newval|
            if oldval.instance_of?(Hash) && newval.instance_of?(Hash)
              _deep_merge(oldval, newval)
            else
              newval
            end
          end
        end
      end
    end
  end
end
