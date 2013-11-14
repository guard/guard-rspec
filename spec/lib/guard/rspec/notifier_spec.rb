require 'spec_helper'

describe Guard::RSpec::Notifier do
  let(:notifier) { Guard::RSpec::Notifier }

  describe '#notify_failure' do
    it 'notifies about failure with failed image' do
      expect(Guard::Notifier).to receive(:notify).with('Failed', hash_including(image: :failed))
      notifier.notify_failure
    end
  end

  describe '#notify' do
    it 'shows summary with success image' do
      expect(Guard::Notifier).to receive(:notify).with('This is summary', hash_including(image: :success))
      notifier.notify('This is summary')
    end

    context 'with pendings' do
      let(:summary) { '5 examples, 0 failures (1 pending) in 4.0000 seconds' }

      it 'notifies with pending image' do
        expect(Guard::Notifier).to receive(:notify).with(summary, hash_including(image: :pending))
        notifier.notify(summary)
      end
    end

    context 'with failures' do
      let(:summary) { '5 examples, 1 failures (1 pending) in 4.0000 seconds' }

      it 'notifies with failed image' do
        expect(Guard::Notifier).to receive(:notify).with(summary, hash_including(image: :failed))
        notifier.notify(summary)
      end
    end
  end
end
