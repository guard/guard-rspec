require 'spec_helper'

describe Guard::RSpec::Notifier do
  let(:options) { { notification: true } }
  let(:notifier) { Guard::RSpec::Notifier.new(options) }

  describe '#notify_failure' do
    it 'notifies about failure with failed image' do
      expect(Guard::Notifier).to receive(:notify).with('Failed', { title: 'RSpec results', image: :failed, priority: 2 })
      notifier.notify_failure
    end
  end

  describe '#notify' do
    it 'shows summary with success image' do
      expect(Guard::Notifier).to receive(:notify).with('This is summary', { title: 'RSpec results', image: :success, priority: -2 })
      notifier.notify('This is summary')
    end

    context 'with pendings' do
      let(:summary) { '5 examples, 0 failures (1 pending) in 4.0000 seconds' }

      it 'notifies with pending image' do
        expect(Guard::Notifier).to receive(:notify).with(summary, { title: 'RSpec results', image: :pending, priority: -1 })
        notifier.notify(summary)
      end
    end

    context 'with failures' do
      let(:summary) { '5 examples, 1 failures (1 pending) in 4.0000 seconds' }

      it 'notifies with failed image' do
        expect(Guard::Notifier).to receive(:notify).with(summary, { title: 'RSpec results', image: :failed, priority: 2 })
        notifier.notify(summary)
      end
    end
  end

  context 'with notifications turned off' do
    let(:options) { { notification: false } }

    describe '#notify_failure' do
      it 'keeps quiet' do
        expect(Guard::Notifier).not_to receive(:notify)
        notifier.notify_failure
      end
    end

    describe '#notify' do
      it 'keeps quiet' do
        expect(Guard::Notifier).not_to receive(:notify)
        notifier.notify('Summary')
      end
    end
  end
end
