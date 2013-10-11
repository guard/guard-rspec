require 'spec_helper'

describe Guard::RSpec::Deprecator do
  let(:options) { {} }
  let(:deprecator) { Guard::RSpec::Deprecator.new(options) }

  describe '#warns_about_deprecated_options' do

    describe 'handling of environment variable SPEC_OPTS' do
      it "shows warning if SPEC_OPTS is set" do
        ENV['SPEC_OPTS'] = '-f p'
        expect(Guard::UI).to receive(:warning).with(
          'The SPEC_OPTS environment variable is present. This can conflict with guard-rspec, particularly notifications.')
        deprecator.warns_about_deprecated_options
        ENV['SPEC_OPTS'] = nil # otherwise other specs pick it up and fail
      end
      it "does not show warning if SPEC_OPTS is unset" do
        expect(Guard::UI).to_not receive(:warning).with(
          'The SPEC_OPTS environment variable is present. This can conflict with guard-rspec, particularly notifications.')
        deprecator.warns_about_deprecated_options
      end
    end

    describe "with version option" do
      let(:options) { { version: 1 } }

      it "shows deprecation warning" do
        expect(Guard::UI).to receive(:warning).with(
          'Guard::RSpec DEPRECATION WARNING: The :version option is deprecated. Only RSpec ~> 2.14 is now supported.')
        deprecator.warns_about_deprecated_options
      end
    end

    describe "with exclude option" do
      let(:options) { { exclude: "**" } }

      it "shows deprecation warning" do
        expect(Guard::UI).to receive(:warning).with(
          'Guard::RSpec DEPRECATION WARNING: The :exclude option is deprecated. Please Guard ignore method instead. https://github.com/guard/guard#ignore')
        deprecator.warns_about_deprecated_options
      end
    end

    %w[color drb fail_fast formatter env bundler binstubs rvm cli spring turnip zeus foreman].each do |option|
      describe "with #{option} option" do
        let(:options) { { option.to_sym => 1 } }

        it "shows deprecation warning" do
          expect(Guard::UI).to receive(:warning).with(
            "Guard::RSpec DEPRECATION WARNING: The :#{option} option is deprecated. Please customize the new :cmd option to fit your need.")
          deprecator.warns_about_deprecated_options
        end
      end
    end

  end
end
