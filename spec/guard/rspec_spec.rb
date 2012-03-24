require 'spec_helper'

describe Guard::RSpec do
  let(:default_options) { { :all_after_pass => true, :all_on_start => true, :keep_failed => true } }
  subject { Guard::RSpec.new }

  let(:inspector) { mock(described_class::Inspector, :excluded= => nil, :spec_paths= => nil, :clean => []) }
  let(:runner)    { mock(described_class::Runner, :set_rspec_version => nil, :rspec_version => nil) }

  before do
    described_class::Runner.stub(:new => runner)
    described_class::Inspector.stub(:new => inspector)
  end

  shared_examples_for "clear failed paths" do
    it "should clear the previously failed paths" do
      inspector.stub(:clean).and_return(["spec/foo"], ["spec/bar"])
      runner.stub(:run).and_return(false, true)

      expect { subject.run_on_change(["spec/foo"]) }.to throw_symbol :task_has_failed
      subject.run_all
      runner.should_receive(:run).with(["spec/bar"], anything)
      expect { subject.run_on_change(["spec/bar"]) }.to throw_symbol :task_has_failed
    end
  end

  describe '.initialize' do
    it "creates an inspector" do
      described_class::Inspector.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
    end

    it "creates a runner" do
      described_class::Runner.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
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
    it "runs all specs specified by the default 'spec_paths' option" do
      runner.should_receive(:run).with(["spec"], anything).and_return(true)
      subject.run_all
    end

    it "should run all specs specified by the 'spec_paths' option" do
      subject = Guard::RSpec.new([], :spec_paths => ["spec", "spec/fixtures/other_spec_path"])
      runner.should_receive(:run).with(["spec", "spec/fixtures/other_spec_path"], anything).and_return(true)
      subject.run_all
    end

    it "passes the default options to the runner" do
      runner.should_receive(:run).with(anything, hash_including(default_options)).and_return(true)
      subject.run_all
    end

    it "passes the message to the runner" do
      runner.should_receive(:run).with(anything, hash_including(:message => "Running all specs")).and_return(true)
      subject.run_all
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      runner.should_receive(:run).with(anything, hash_including(:cli => "--color")).and_return(true)
      subject.run_all
    end

    it "allows the :run_all options to override the default_options" do
      subject = Guard::RSpec.new([], { :rvm => ['1.8.7', '1.9.2'], :cli => "--color", :run_all => { :cli => "--format progress" } })
      runner.should_receive(:run).with(anything, hash_including(:cli => "--format progress", :rvm => ['1.8.7', '1.9.2'])).and_return(true)
      subject.run_all
    end

    it "throws task_has_failed if specs aren't passed" do
      runner.should_receive(:run).and_return(false)
      expect { subject.run_all }.to throw_symbol :task_has_failed
    end

    it_should_behave_like "clear failed paths"
  end

  describe "#reload" do
    it_should_behave_like "clear failed paths"
  end

  describe "#run_on_change" do
    it "runs rspec with paths" do
      inspector.stub(:clean => ["spec/foo"])
      runner.should_receive(:run).with(["spec/foo"], anything).and_return(true)
      subject.run_on_change(["spec/foo"])
    end

    it "directly passes :cli option to runner" do
      subject = Guard::RSpec.new([], { :cli => "--color" })
      runner.should_receive(:run).with(anything, hash_including(:cli => "--color")).and_return(true)
      subject.run_on_change(["spec/foo"])
    end

    context "the changed specs pass after failing" do
      before { runner.stub(:run).and_return(false, true) }

      it "calls #run_all" do
        subject.should_receive(:run_all)
        expect { subject.run_on_change(["spec/foo"]) }.to throw_symbol :task_has_failed
        subject.run_on_change(["spec/foo"])
      end

      context "but the :all_after_pass option is false" do
        let(:subject) { Guard::RSpec.new([], :all_after_pass => false) }

        it "doesn't call #run_all" do
          subject.should_not_receive(:run_all)
          expect { subject.run_on_change(["spec/foo"]) }.to throw_symbol :task_has_failed
          subject.run_on_change(["spec/foo"])
        end
      end
    end

    context "the changed specs pass without failing" do
      before { runner.stub(:run).and_return(true) }

      it "doesn't call #run_all " do
        subject.should_not_receive(:run_all)
        subject.run_on_change(["spec/foo"])
      end
    end

    it "should keep failed spec and rerun later" do
      inspector.stub(:clean => ["spec/bar"])

      runner.stub(:run).and_return(false)
      expect { subject.run_on_change(["spec/foo"]) }.to throw_symbol :task_has_failed
      runner.stub(:run).and_return(true)
      subject.run_on_change(["spec/bar"])
      runner.should_receive(:run).with(["spec/bar"], anything)
      subject.run_on_change(["spec/bar"])
    end

    it "throws task_has_failed if specs aren't passed" do
      runner.should_receive(:run).and_return(false)
      expect { subject.run_on_change(["spec/bar"]) }.to throw_symbol :task_has_failed
    end
  end

end

