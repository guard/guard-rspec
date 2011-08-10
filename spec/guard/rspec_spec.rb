require 'spec_helper'

describe Guard::RSpec do
  let(:default_options) { { :all_after_pass => true, :all_on_start => true, :keep_failed => true } }
  subject { Guard::RSpec.new }

  shared_examples_for "clear failed paths" do
    it "should clear the previously failed paths" do
      Guard::RSpec::Runner.stub(:run).and_return(false, true)
      subject.run_on_change(["spec/foo"])
      subject.run_all
      Guard::RSpec::Runner.should_receive(:run).with(["spec/bar"], anything)
      subject.run_on_change(["spec/bar"])
    end
  end

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
      subject.should_receive(:run_all)
      subject.start
    end

    context ":all_on_start option is false" do
      let(:subject) { subject = Guard::RSpec.new([], :all_on_start => false) }

      it "doesn't call #run_all" do
        subject.should_not_receive(:run_all)
        subject.start
      end
    end
  end

  describe "#run_all" do
    it "runs all specs in the 'spec/' directory" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/"], anything)
      subject.run_all
    end

    it "passes the default options to the runner" do
      Guard::RSpec::Runner.should_receive(:run).with(anything, hash_including(default_options))
      subject.run_all
    end

    it "passes the message to the runner" do
      Guard::RSpec::Runner.should_receive(:run).with(anything, hash_including(:message => "Running all specs"))
      subject.run_all
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      Guard::RSpec::Runner.should_receive(:run).with(anything, hash_including(:cli => "--color"))
      subject.run_all
    end

    it "allows the :run_all options to override the default_options" do
      subject = Guard::RSpec.new([], { :rvm => ['1.8.7', '1.9.2'], :cli => "--color", :run_all => { :cli => "--format progress" } })
      Guard::RSpec::Runner.should_receive(:run).with(anything, hash_including(:cli => "--format progress", :rvm => ['1.8.7', '1.9.2']))
      subject.run_all
    end

    it_should_behave_like "clear failed paths"

  end

  describe "#reload" do
    it_should_behave_like "clear failed paths"
  end

  describe "#run_on_change" do
    it "runs rspec with paths" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec/foo"], anything)
      subject.run_on_change(["spec/foo"])
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      Guard::RSpec::Runner.should_receive(:run).with(anything, hash_including(:cli => "--color"))
      subject.run_on_change(["spec/foo"])
    end

    context "the changed specs pass after failing" do
      before { Guard::RSpec::Runner.stub(:run).and_return(false, true) }

      it "calls #run_all" do
        subject.should_receive(:run_all)
        2.times { subject.run_on_change(["spec/foo"]) }
      end

      context "but the :all_after_pass option is false" do
        let(:subject) { Guard::RSpec.new([], :all_after_pass => false) }

        it "doesn't call #run_all" do
          subject.should_not_receive(:run_all)
          2.times { subject.run_on_change(["spec/foo"]) }
        end
      end
    end

    context "the changed specs pass without failing" do
      before { Guard::RSpec::Runner.stub(:run).and_return(true) }

      it "doesn't call #run_all " do
        subject.should_not_receive(:run_all)
        subject.run_on_change(["spec/foo"])
      end
    end

    it "should keep failed spec and rerun later" do
      Guard::RSpec::Runner.stub(:run).and_return(false)
      subject.run_on_change(["spec/foo"])
      Guard::RSpec::Runner.stub(:run).and_return(true)
      subject.run_on_change(["spec/bar"])
      Guard::RSpec::Runner.should_receive(:run).with(["spec/bar"], anything)
      subject.run_on_change(["spec/bar"])
    end
  end

end

