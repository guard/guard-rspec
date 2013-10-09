require 'spec_helper'

describe Guard::RSpec::Deprecator do

  # describe '.initialize' do

  #   describe 'handling of environment variable SPEC_OPTS' do
  #     it "shows warning if SPEC_OPTS is set" do
  #       ENV['SPEC_OPTS'] = '-f p'
  #       expect(Guard::UI).to receive(:warning).with(
  #         "The SPEC_OPTS environment variable is present. This can conflict with guard-rspec, particularly notifications."
  #       ).ordered
  #       described_class.new
  #       ENV['SPEC_OPTS'] = nil # otherwise other specs pick it up and fail
  #     end
  #     it "does not show warning if SPEC_OPTS is unset" do
  #       expect(Guard::UI).to_not receive(:warning).with(
  #         "The SPEC_OPTS environment variable is present. This can conflict with guard-rspec, particularly notifications."
  #       ).ordered
  #       described_class.new
  #     end
  #   end

  #   describe "shows warnings when using zeus and bundler together" do
  #     it 'shows warning if bundler: true, zeus: true' do
  #       expect(Guard::UI).to receive(:warning).with(
  #         "Running Zeus within bundler is waste of time. Bundler option is set to false, when using Zeus."
  #       ).ordered
  #       described_class.new(bundler: true, zeus: true)
  #     end

  #     it 'does not show warning if bundler: false, zeus: true' do
  #       expect(Guard::UI).to_not receive(:warning).with(
  #         "Running Zeus within bundler is waste of time. Bundler option is set to false, when using Zeus."
  #       ).ordered
  #       described_class.new(bundler: false, zeus: true)
  #     end

  #     it 'does not show warning if bundler: true, zeus: false' do
  #       expect(Guard::UI).to_not receive(:warning).with(
  #         "Running Zeus within bundler is waste of time. Bundler option is set to false, when using Zeus."
  #       ).ordered
  #       described_class.new(bundler: true, zeus: false)
  #     end

  #     it 'does not show warning if zeus: true, binstubs: true' do
  #       expect(Guard::UI).to_not receive(:warning).with(
  #         "Running Zeus within bundler is waste of time. Bundler option is set to false, when using Zeus."
  #       ).ordered
  #       described_class.new(zeus: true, binstubs: true)
  #     end
  #   end

  #   describe "shows warnings when using spring and bundler together" do
  #     it 'shows warning if bundler: true, spring: true' do
  #       expect(Guard::UI).to receive(:warning).with(
  #         "Running Spring within bundler is waste of time. Bundler option is set to false, when using Spring."
  #       ).ordered
  #       described_class.new(bundler: true, spring: true)
  #     end

  #     it 'does not show warning if bundler: false, spring: true' do
  #       expect(Guard::UI).to_not receive(:warning).with(
  #         "Running Spring within bundler is waste of time. Bundler option is set to false, when using Spring."
  #       ).ordered
  #       described_class.new(bundler: false, spring: true)
  #     end

  #     it 'does not show warning if bundler: true, spring: false' do
  #       expect(Guard::UI).to_not receive(:warning).with(
  #         "Running Spring within bundler is waste of time. Bundler option is set to false, when using Spring."
  #       ).ordered
  #       described_class.new(bundler: true, spring: false)
  #     end

  #     it 'does not show warning if spring: true, binstubs: true' do
  #       expect(Guard::UI).to_not receive(:warning).with(
  #         "Running Spring within bundler is waste of time. Bundler option is set to false, when using Spring."
  #       ).ordered
  #       described_class.new(spring: true, binstubs: true)
  #     end
  #   end

  #   describe 'shows warnings for deprecated options' do
  #     [:color, :drb, [:fail_fast, 'fail-fast'], [:formatter, 'format']].each do |option|
  #       key, value = option.is_a?(Array) ? option : [option, option.to_s]
  #       it "outputs deprecation warning for :#{key} option" do
  #         expect(Guard::UI).to receive(:info).with(
  #           "DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line " <<
  #           %(argument "--#{value}" to RSpec with the :cli option.)
  #         ).ordered
  #         described_class.new(key => 'foo')
  #       end
  #     end
  #   end
  # end

end
