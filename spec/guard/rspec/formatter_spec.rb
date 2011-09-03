require "#{File.dirname(__FILE__)}/../../../lib/guard/rspec/formatter"

describe Guard::RSpec::Formatter do

  subject { Class.new { include Guard::RSpec::Formatter }.new }

  describe "#guard_message" do
    context 'with a pending example' do
      it "returns the notification message" do
        subject.guard_message(10, 2, 0, 5.1234567).should eql "10 examples, 2 failures\nin 5.1235 seconds"
      end
    end

    context 'without a pending example' do
      it "returns the notification message" do
        subject.guard_message(10, 2, 1, 3.9876543).should eql "10 examples, 2 failures (1 pending)\nin 3.9877 seconds"
      end
    end
  end

  describe "#guard_image" do
    context "with at least a failed example" do
      it "always returns :failed" do
        subject.guard_image(1, 0).should eql :failed
      end
    end

    context "with at least a pending example" do
      it "returns :failed when there is at least one failed example" do
        subject.guard_image(1, 1).should eql :failed
      end

      it "returns :pending when there is no failed example" do
        subject.guard_image(0, 1).should eql :pending
      end
    end

    it "returns :success when no example failed or is pending" do
      subject.guard_image(0, 0).should eql :success
    end
  end

  describe "#priority" do
    it "returns the failed priority" do
      subject.priority(:failed).should eql 2
    end

    it "returns the pending priority" do
      subject.priority(:pending).should eql -1
    end

    it "returns the success priority" do
      subject.priority(:success).should eql -2
    end
  end

  describe "#notify" do
    it "calls the guard notifier" do
      Guard::Notifier.should_receive(:notify).with(
          "This is the guard rspec message",
          :title => "RSpec results",
          :image => :success,
          :priority => -2
      )
      subject.notify("This is the guard rspec message", :success)
    end
  end
end
