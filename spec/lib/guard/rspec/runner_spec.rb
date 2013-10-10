require 'spec_helper'
require 'launchy'

describe Guard::RSpec::Runner do
  let(:default_options) { {
    all_after_pass:  false,
    notification: true,
    run_all: { message: 'Running all specs' },
    launchy: nil,
  } }
  let(:options) { {} }
  let(:runner) { Guard::RSpec::Runner.new(options) }
  let(:inspector) { double(Guard::RSpec::Inspector) }
  before {
    Guard::UI.stub(:info)
    Kernel.stub(:system) { true }
    Guard::RSpec::Inspector.stub(:new) { inspector }
    Guard::RSpec::Command.stub(:new) { 'rspec' }
  }

  describe '.initialize' do
    it 'instanciates inspector with options' do
      expect(Guard::RSpec::Inspector).to receive(:new).with(default_options.merge(foo: :bar))
      Guard::RSpec::Runner.new(foo: :bar)
    end
  end

  describe "#reloads" do
    it "clears inspector failed_paths" do
      expect(inspector).to receive(:clear_paths)
      runner.reload
    end
  end

  describe "#run_all" do
    before {
      inspector.stub(:paths) { %w[spec1 spec2] }
      inspector.stub(:clear_paths) { true }
    }

    it "prints default message" do
      expect(Guard::UI).to receive(:info).with(default_options[:run_all][:message], reset: true)
      runner.run_all
    end

    context "with custom message" do
      let(:options) { { run_all: { message: 'Custom message' } } }

      it "prints custom message" do
        expect(Guard::UI).to receive(:info).with('Custom message', reset: true)
        runner.run_all
      end
    end

    context "with custom cmd" do
      let(:options) { { run_all: { cmd: 'rspec -t ~slow' } } }

      it "builds command with custom options" do
        expect(Guard::RSpec::Command).to receive(:new).with(kind_of(Array), hash_including(cmd: 'rspec -t ~slow'))
        runner.run_all
      end
    end

    it "builds commands with all spec paths" do
      expect(Guard::RSpec::Command).to receive(:new).with(%w[spec1 spec2], kind_of(Hash))
      runner.run_all
    end

    it "clears inspector paths if run is success" do
      expect(inspector).to receive(:clear_paths)
      runner.run_all
    end
  end

  describe "#run" do
    let(:paths) { %w[spec_path1 spec_path2] }
    before {
      inspector.stub(:failed_paths) { [] }
      inspector.stub(:paths) { paths }
      inspector.stub(:clear_paths) { true }
    }

    it "prints running message" do
      expect(Guard::UI).to receive(:info).with('Running: spec_path1 spec_path2', reset: true)
      runner.run(paths)
    end

    it "returns if no paths are given" do
      inspector.stub(:paths) { [] }
      expect(Guard::UI).to_not receive(:info)
      runner.run([])
    end

    it "builds commands with spec paths" do
      expect(Guard::RSpec::Command).to receive(:new).with(%w[spec_path1 spec_path2], kind_of(Hash))
      runner.run(paths)
    end

    it "clears inspector paths if run is success" do
      expect(inspector).to receive(:clear_paths).with(paths)
      runner.run(paths)
    end

    it "notifies failure" do
      Kernel.stub(:system) { false }
      expect(Guard::Notifier).to receive(:notify).with('Failed', title: 'RSpec results', image: :failed, priority: 2)
      runner.run(paths)
    end

    context "with all_after_pass option and old failed spec paths" do
      let(:options) { { all_after_pass: true } }
      before {
        inspector.stub(:failed_paths) { %w[failed_path] }
        inspector.stub(:paths).with(paths) { paths }
      }

      it "re-runs all if run is success" do
        expect(runner).to receive(:run_all)
        runner.run(paths)
      end
    end

    context "with launchy option" do
      let(:options) { { launchy: 'launchy_path' } }
      before {
        Pathname.stub(:new).with('launchy_path') { double(exist?: true) }
      }

      it "opens Launchy" do
        expect(Launchy).to receive(:open).with('launchy_path')
        runner.run(paths)
      end
    end
  end

end
