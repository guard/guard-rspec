require 'spec_helper'
require 'launchy'

describe Guard::RSpec::Runner do
  let(:options) { {} }
  let(:runner) { Guard::RSpec::Runner.new(options) }
  let(:inspector) { double(Guard::RSpec::Inspectors::SimpleInspector) }
  let(:notifier) { double(Guard::RSpec::Notifier) }
  let(:formatter_tmp_file) { Guard::RSpec::Formatter::TEMPORARY_FILE_PATH }
  before {
    allow(Guard::UI).to receive(:info)
    allow(Kernel).to receive(:system) { true }
    allow(Guard::RSpec::Inspectors::Factory).to receive(:create) { inspector }
    allow(Guard::RSpec::Notifier).to receive(:new) { notifier }
    allow(Guard::RSpec::Command).to receive(:new) { 'rspec' }
    allow(notifier).to receive(:notify)
    allow(notifier).to receive(:notify_failure)
  }

  describe '.initialize' do
    context 'with custom options' do
      let(:options) { { foo: :bar } }

      it 'instanciates inspector via Inspectors::Factory with custom options' do
        expect(Guard::RSpec::Inspectors::Factory).to receive(:create).with(foo: :bar)
        runner
      end

      it 'instanciates notifier with custom options' do
        expect(Guard::RSpec::Notifier).to receive(:new).with(foo: :bar)
        runner
      end
    end
  end

  describe '#reload' do
    it 'calls inspector\'s #reload' do
      expect(inspector).to receive(:reload)
      runner.reload
    end
  end

  shared_examples 'abort' do
    it 'aborts' do
      expect(Guard::UI).to_not receive(:info)
      subject
    end

    it 'returns true' do
      expect(subject).to be true
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

    context 'when no paths are given' do
      subject { runner.run_all }

      let(:options) { {
        spec_paths: [],
        run_all: { message: 'Custom message' }
      } }

      include_examples 'abort'
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
      allow(File).to receive(:readlines).with(formatter_tmp_file) { %W{Summary\n} }
      allow(inspector).to receive(:paths) { paths }
      allow(inspector).to receive(:clear_paths) { true }
      allow(inspector).to receive(:failed)
    }

    it 'prints running message' do
      expect(Guard::UI).to receive(:info).with('Running: spec_path1 spec_path2', reset: true)
      runner.run(paths)
    end

    context 'when no paths are given' do
      subject { runner.run([]) }

      before do
        allow(inspector).to receive(:paths) { [] }
      end

      include_examples 'abort'
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
        allow(Pathname).to receive(:new).with('launchy_path') { double(exist?: true) }
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
        allow(File).to receive(:readlines).with(formatter_tmp_file) { %W{Summary\n ./failed_spec.rb:123\n ./other/failed_spec.rb:77\n} }
      }

      it 'notifies inspector about failed paths' do
        expect(inspector).to receive(:failed).with(%w[./failed_spec.rb:123 ./other/failed_spec.rb:77])
        runner.run(paths)
      end
    end

    it 'notifies success' do
      expect(notifier).to receive(:notify).with('Summary')
      runner.run(paths)
    end

    it 'notifies failure' do
      allow(Kernel).to receive(:system) { nil }
      expect(notifier).to receive(:notify_failure)
      runner.run(paths)
    end
  end
end
