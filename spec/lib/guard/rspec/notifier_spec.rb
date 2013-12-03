require 'spec_helper'

describe Guard::RSpec::Notifier do
  let(:options) { { notification: true } }
  let(:notifier) { Guard::RSpec::Notifier.new(options) }

  def expect_notification(message, image, priority)
    expect(Guard::Notifier).to receive(:notify).with(message, { title: 'RSpec results', image: image, priority: priority })
  end

  describe '#notify_failure' do
    it 'notifies about failure' do
      expect_notification('Failed', :failed, 2)
      notifier.notify_failure
    end
  end

  describe '#notify' do
    it 'notifies about success' do
      expect_notification('This is summary', :success, -2)
      notifier.notify('This is summary')
    end

    context 'with pendings' do
      let(:summary) { '5 examples, 0 failures (1 pending) in 4.0000 seconds' }

      it 'notifies about pendings' do
        expect_notification(summary, :pending, -1)
        notifier.notify(summary)
      end
    end

    context 'with failures' do
      let(:summary) { '5 examples, 1 failures in 4.0000 seconds' }

      it 'notifies about failures' do
        expect_notification(summary, :failed, 2)
        notifier.notify(summary)
      end

      context 'even if there is pendings' do
        let(:summary) { '5 examples, 1 failures (1 pending) in 4.0000 seconds' }

        it 'still notifies about failures' do
          expect_notification(summary, :failed, 2)
          notifier.notify(summary)
        end
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
