require 'spec_helper'

describe Guard::RSpec do
  let(:default_options) { { all_on_start: false } }
  let(:options) { { } }
  let(:plugin) { Guard::RSpec.new(options) }
  let(:runner) { double(Guard::RSpec::Runner) }
  before {
    Guard::UI.stub(:info)
    Guard::RSpec::Deprecator.stub(:warns_about_deprecated_options)
    Guard::RSpec::Runner.stub(:new) { runner }
  }

  describe '.initialize' do
    it 'instanciates Runner with options' do
      expect(Guard::RSpec::Runner).to receive(:new).with(default_options.merge(foo: :bar))
      Guard::RSpec.new(foo: :bar)
    end

    it 'warns deprecated options' do
      expect(Guard::RSpec::Deprecator).to receive(:warns_about_deprecated_options).with(default_options.merge(foo: :bar))
      Guard::RSpec.new(foo: :bar)
    end
  end

  describe '#start' do
    it "doesn't call #run_all by default" do
      expect(plugin).to_not receive(:run_all)
      plugin.start
    end

    context 'with all_on_start at true' do
      let(:options) { { all_on_start: true } }

      it 'calls #run_all' do
        expect(plugin).to receive(:run_all)
        plugin.start
      end
    end
  end

  describe '#run_all' do
    it "runs all specs via runner" do
      expect(runner).to receive(:run_all) { true }
      plugin.run_all
    end

    it "throws task_has_failed if runner return false" do
      runner.stub(:run_all) { false }
      expect(plugin).to receive(:throw).with(:task_has_failed)
      plugin.run_all
    end
  end

  describe '#reload' do
    it "reloads via runner" do
      expect(runner).to receive(:reload)
      plugin.reload
    end
  end

  describe '#run_on_modifications' do
    let(:paths) { %w[path1 path2] }
    it "runs all specs via runner" do
      expect(runner).to receive(:run).with(paths) { true }
      plugin.run_on_modifications(paths)
    end

    it "does nothing if paths empty" do
      expect(runner).to_not receive(:run)
      plugin.run_on_modifications([])
    end

    it "throws task_has_failed if runner return false" do
      runner.stub(:run) { false }
      expect(plugin).to receive(:throw).with(:task_has_failed)
      plugin.run_on_modifications(paths)
    end
  end

end

