require 'spec_helper'
require 'launchy'

describe Guard::RSpec::Runner do
  let(:options) { {} }
  let(:runner) { Guard::RSpec::Runner.new(options) }
  let(:inspector) { double(Guard::RSpec::Inspectors::SimpleInspector) }
  before {
    Guard::UI.stub(:info)
    Kernel.stub(:system) { true }
    Guard::RSpec::Inspectors::Factory.stub(:create) { inspector }
    Guard::RSpec::Command.stub(:new) { 'rspec' }
  }

  describe '.initialize' do
    context 'with custom options' do
      let(:options) { { foo: :bar } }

      it 'instanciates inspector via Inspectors::Factory with custom options' do
        expect(Guard::RSpec::Inspectors::Factory).to receive(:create).with(foo: :bar)
        Guard::RSpec::Runner.new(options)
      end
    end
  end

  describe '#reload' do
    it 'calls inspector\'s #reload' do
      expect(inspector).to receive(:reload)
      runner.reload
    end
  end

  describe '#run_all' do
    let(:options) { {
      spec_paths: %w[spec1 spec2],
      run_all: { message: 'Custom message' }
    } }

    it 'builds commands with spec paths' do
      expect(Guard::RSpec::Command).to receive(:new).with(%w[spec1 spec2], kind_of(Hash))
      runner.run_all
    end

    it 'prints message' do
      expect(Guard::UI).to receive(:info).with('Custom message', reset: true)
      runner.run_all
    end

    context 'with custom cmd' do
      before {
        options[:run_all][:cmd] = 'rspec -t ~slow'
      }

      it 'builds command with custom cmd' do
        expect(Guard::RSpec::Command).to receive(:new).with(kind_of(Array), hash_including(cmd: 'rspec -t ~slow'))
        runner.run_all
      end
    end
  end

  describe '#run' do
    let(:paths) { %w[spec_path1 spec_path2] }
    before {
      runner.stub(:_command_output) { ['summary', []] }
      inspector.stub(:paths) { paths }
      inspector.stub(:clear_paths) { true }
      inspector.stub(:failed)
    }

    it 'prints running message' do
      expect(Guard::UI).to receive(:info).with('Running: spec_path1 spec_path2', reset: true)
      runner.run(paths)
    end

    it 'returns if no paths are given' do
      inspector.stub(:paths) { [] }
      expect(Guard::UI).to_not receive(:info)
      runner.run([])
    end

    it 'builds commands with spec paths' do
      expect(Guard::RSpec::Command).to receive(:new).with(%w[spec_path1 spec_path2], kind_of(Hash))
      runner.run(paths)
    end

    context 'with all_after_pass option' do
      let(:options) { { all_after_pass: true } }

      it 're-runs all if run is success' do
        expect(runner).to receive(:run_all)
        runner.run(paths)
      end
    end

    context 'with launchy option' do
      let(:options) { { launchy: 'launchy_path' } }

      before {
        Pathname.stub(:new).with('launchy_path') { double(exist?: true) }
      }

      it 'opens Launchy' do
        expect(Launchy).to receive(:open).with('launchy_path')
        runner.run(paths)
      end
    end

    it 'notifies inspector about failed paths' do
      expect(inspector).to receive(:failed).with([])
      runner.run(paths)
    end

    context 'with failed paths' do
      before {
        runner.stub(:_command_output) { ['summary', %w[failed_spec other_failed_spec]] }
      }

      it 'notifies inspector about failed paths' do
        expect(inspector).to receive(:failed).with(%w[failed_spec other_failed_spec])
        runner.run(paths)
      end
    end

    it 'notifies success' do
      expect(Guard::RSpec::Notifier).to receive(:notify).with('summary')
      runner.run(paths)
    end

    it 'notifies failure' do
      Kernel.stub(:system) { nil }
      expect(Guard::RSpec::Notifier).to receive(:notify_failure)
      runner.run(paths)
    end
  end
end
