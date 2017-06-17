require "guard/compat/test/helper"
require "guard/rspec/plugin"

RSpec.describe Guard::RSpec::Plugin do
  let(:default_options) { Guard::RSpec::Options::DEFAULTS }
  let(:options) { {} }
  let(:plugin) { described_class.new(options) }
  let(:runner) { instance_double(Guard::RSpec::Runner) }

  before do
    allow(Guard::Compat::UI).to receive(:info)
    allow(Guard::RSpec::Deprecator).to receive(:warns_about_deprecated_options)
    allow(Guard::RSpec::Runner).to receive(:new) { runner }
  end

  describe ".initialize" do
    let(:options) { { foo: :bar } }

    it "instanciates with default and custom options" do
      expect(plugin.options).to eq(default_options.merge(options))
    end

    it "instanciates Runner with all default and custom options" do
      expect(Guard::RSpec::Runner).to receive(:new).
        with(default_options.merge(options))

      plugin
    end

    it "warns deprecated options" do
      expect(Guard::RSpec::Deprecator).
        to receive(:warns_about_deprecated_options).
        with(default_options.merge(options))

      plugin
    end
  end

  describe "#start" do
    it "doesn't call #run_all by default" do
      expect(plugin).to_not receive(:run_all)
      plugin.start
    end

    context "with all_on_start at true" do
      let(:options) { { all_on_start: true } }

      it "calls #run_all" do
        expect(plugin).to receive(:run_all)
        plugin.start
      end
    end
  end

  describe "#run_all" do
    it "runs all specs via runner" do
      expect(runner).to receive(:run_all) { true }
      plugin.run_all
    end

    it "throws task_has_failed if runner return false" do
      allow(runner).to receive(:run_all) { false }
      expect(plugin).to receive(:throw).with(:task_has_failed)
      plugin.run_all
    end
  end

  describe "#reload" do
    it "reloads via runner" do
      expect(runner).to receive(:reload)
      plugin.reload
    end
  end

  describe "#run_on_modifications" do
    let(:paths) { %w(path1 path2) }
    it "runs all specs via runner" do
      expect(runner).to receive(:run).with(paths) { true }
      plugin.run_on_modifications(paths)
    end

    it "does nothing if paths empty" do
      expect(runner).to_not receive(:run)
      plugin.run_on_modifications([])
    end

    it "throws task_has_failed if runner return false" do
      allow(runner).to receive(:run) { false }
      expect(plugin).to receive(:throw).with(:task_has_failed)
      plugin.run_on_modifications(paths)
    end
  end
end
