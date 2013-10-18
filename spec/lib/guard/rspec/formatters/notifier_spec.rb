require 'spec_helper.rb'

require 'guard/rspec/formatters/notifier'

describe Guard::RSpec::Formatters::Notifier do
  let(:formatter) { Guard::RSpec::Formatters::Notifier.new(StringIO.new) }

  describe "#dump_summary" do
    before {
      Guard::Notifier.stub(:turn_on)
      Guard::Notifier.stub(:notify)
    }

    it "turns on Notifier" do
      expect(Guard::Notifier).to receive(:turn_on).with(silent: true)
      formatter.dump_summary(123, 3, 0, 0)
    end

    context "with only success" do
      it "notifies success" do
        expect(Guard::Notifier).to receive(:notify).with(
          "3 examples, 0 failures\nin 123.0 seconds", title: "RSpec results", image: :success, priority:-2)
        formatter.dump_summary(123, 3, 0, 0)
      end
    end

    context "with pending" do
      it "notifies pending too" do
        expect(Guard::Notifier).to receive(:notify).with(
          "3 examples, 0 failures (1 pending)\nin 123.0 seconds", title: "RSpec results", image: :pending, priority:-1)
        formatter.dump_summary(123, 3, 0, 1)
      end
    end

    context "with failures" do
      it "notifies failures too" do
        expect(Guard::Notifier).to receive(:notify).with(
          "3 examples, 1 failures\nin 123.0 seconds", title: "RSpec results", image: :failed, priority:2)
        formatter.dump_summary(123, 3, 1, 0)
      end
    end
  end

end
