require 'spec_helper'

describe Guard::RSpec do
  let(:default_options) { { :all_after_pass => true, :all_on_start => true, :keep_failed => true } }
  subject { Guard::RSpec.new }

  describe '#initialize' do
    it 'sets rspec_version' do
      Guard::RSpec::Runner.should_receive(:set_rspec_version)
      Guard::RSpec.new
    end

    it 'passes an excluded spec glob to Inspector' do
      Guard::RSpec::Inspector.should_receive(:excluded=).with('spec/slow/*')
      Guard::RSpec.new([], :exclude => 'spec/slow/*')
    end
  end

  describe "#start" do
    it "calls #run_all" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs"))
      subject.start
    end

    it "doesn't call #run_all if the :all_on_start option is false" do
      Guard::RSpec::Runner.should_not_receive(:run).with(["spec"], default_options.merge(:all_on_start => false, :message => "Running all specs"))
      subject = Guard::RSpec.new([], :all_on_start => false)
      subject.start
    end
  end

  describe "#run_all" do
    it "runs all specs" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs"))
      subject.run_all
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs", :cli => "--color"))
      subject.run_all
    end

    it "should clean failed memory if passed" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], default_options).and_return(false)
      subject.run_on_change(["spec/foo"])
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs")).and_return(true)
      subject.run_all
      Guard::RSpec::Runner.should_receive(:run).with(["spec/bar"], default_options).and_return(true)
      subject.run_on_change(["spec/bar"])
    end
  end

  describe "#reload" do
    it "should clear failed_path" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], default_options).and_return(false)
      subject.run_on_change(["spec/foo"])
      subject.reload
      Guard::RSpec::Runner.should_receive(:run).with(["spec/bar"], default_options).and_return(true)
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs")).and_return(true)
      subject.run_on_change(["spec/bar"])
    end
  end

  describe "#run_on_change" do
    it "runs rspec with paths" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options)
      subject.run_on_change(["spec"])
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:cli => "--color"))
      subject.run_on_change(["spec"])
    end

    it "calls #run_all if the changed specs pass after failing" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], default_options).and_return(false, true)
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs"))
      subject.run_on_change(["spec/foo"])
      subject.run_on_change(["spec/foo"])
    end

    it "doesn't call #run_all if the changed specs pass after failing but the :all_after_pass option is false" do
      subject = Guard::RSpec.new([], :all_after_pass => false)
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], default_options.merge(:all_after_pass => false)).and_return(false, true)
      Guard::RSpec::Runner.should_not_receive(:run).with(["spec"], default_options.merge(:all_after_pass => false, :message => "Running all specs"))
      subject.run_on_change(["spec/foo"])
      subject.run_on_change(["spec/foo"])
    end

    it "doesn't call #run_all if the changed specs pass without failing" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], default_options).and_return(true)
      Guard::RSpec::Runner.should_not_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs"))
      subject.run_on_change(["spec/foo"])
    end

    it "should keep failed spec and rerun later" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], default_options).and_return(false)
      subject.run_on_change(["spec/foo"])
      Guard::RSpec::Runner.should_receive(:run).with(["spec/bar", "spec/foo"], default_options).and_return(true)
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], default_options.merge(:message => "Running all specs")).and_return(true)
      subject.run_on_change(["spec/bar"])
      Guard::RSpec::Runner.should_receive(:run).with(["spec/bar"], default_options).and_return(true)
      subject.run_on_change(["spec/bar"])
    end
  end

end
