require 'spec_helper'

describe Guard::RSpec do
  subject { Guard::RSpec.new }

  describe '#initialize' do
    it 'sets rspec_version' do
      Guard::RSpec::Runner.should_receive(:set_rspec_version)
      Guard::RSpec.new
    end
  end

  describe "#start" do
    it "calls #run_all" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], :message => "Running all specs")
      subject.start
    end

    it "doesn't call #run_all if the :all_on_start option is false" do
      Guard::RSpec::Runner.should_not_receive(:run).with(["spec"], :message => "Running all specs")
      subject = Guard::RSpec.new([], :all_on_start => false)
      subject.start
    end
  end

  describe "#run_all" do
    it "runs all specs" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], :message => "Running all specs")
      subject.run_all
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], :message => "Running all specs", :cli => "--color")
      subject.run_all
    end
  end

  describe "#run_on_change" do
    it "runs rspec with paths" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], {})
      subject.run_on_change(["spec"])
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], :cli => "--color")
      subject.run_on_change(["spec"])
    end

    it "calls #run_all if the changed specs pass after failing" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], {}).and_return(false, true)
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], :message => "Running all specs")
      subject.run_on_change(["spec/foo"])
      subject.run_on_change(["spec/foo"])
    end

    it "doesn't call #run_all if the changed specs pass after failing but the :all_after_pass option is false" do
      subject = Guard::RSpec.new([], :all_after_pass => false)
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], {}).and_return(false, true)
      Guard::RSpec::Runner.should_not_receive(:run).with(["spec"], :message => "Running all specs")
      subject.run_on_change(["spec/foo"])
      subject.run_on_change(["spec/foo"])
    end

    it "doesn't call #run_all if the changed specs pass without failing" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], {}).and_return(true)
      Guard::RSpec::Runner.should_not_receive(:run).with(["spec"], :message => "Running all specs")
      subject.run_on_change(["spec/foo"])
    end
  end

end
