require 'spec_helper'
require 'fileutils'

describe Guard::RSpec do
  let(:default_options) do
    {
      :all_after_pass => false, :all_on_start => false, :keep_failed => false,
      :spec_paths => ['spec'], :run_all => {}, :focus_on_failed => false
    }
  end
  subject { described_class.new }

  let(:inspector) { mock(described_class::Inspector, :excluded= => nil, :spec_paths => ['spec'], :clean => []) }
  let(:runner)    { mock(described_class::Runner, :set_rspec_version => nil, :rspec_version => nil) }

  before do
    described_class::Runner.stub(:new => runner)
    described_class::Inspector.stub(:new => inspector)
  end

  shared_examples_for 'clear failed paths' do
    it 'should clear the previously failed paths' do
      inspector.stub(:clean).and_return(['spec/foo'], ['spec/bar'])

      runner.should_receive(:run).with(['spec/foo']) { false }
      expect { subject.run_on_changes(['spec/foo']) }.to throw_symbol :task_has_failed

      runner.should_receive(:run) { true }
      expect { subject.run_all }.to_not throw_symbol # this actually clears the failed paths

      runner.should_receive(:run).with(['spec/bar']) { true }
      subject.run_on_changes(['spec/bar'])
    end
  end

  describe '.initialize' do
    it 'creates an inspector' do
      described_class::Inspector.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
    end

    it 'creates a runner' do
      described_class::Runner.should_receive(:new).with(default_options.merge(:foo => :bar))

      described_class.new([], :foo => :bar)
    end
  end

  describe '#start' do
    it "doesn't call #run_all" do
      subject.should_not_receive(:run_all)
      subject.start
    end

    context ':all_on_start option is true' do
      let(:subject) { subject = described_class.new([], :all_on_start => true) }

      it 'calls #run_all' do
        subject.should_receive(:run_all)
        subject.start
      end
    end
  end

  describe '#run_all' do
    it "runs all specs specified by the default 'spec_paths' option" do
      runner.should_receive(:run).with(['spec'], anything) { true }

      subject.run_all
    end

    it "should run all specs specified by the 'spec_paths' option" do
      inspector.stub(:spec_paths) { ['spec', 'spec/fixtures/other_spec_path'] }
      runner.should_receive(:run).with(['spec', 'spec/fixtures/other_spec_path'], anything) { true }

      subject.run_all
    end

    it 'passes the :run_all options' do
      subject = described_class.new([], {
        :rvm => ['1.8.7', '1.9.2'], :cli => '--color', :run_all => { :cli => '--format progress' }
      })
      runner.should_receive(:run).with(['spec'], hash_including(:cli => '--format progress')) { true }

      subject.run_all
    end

    it 'passes the message to the runner' do
      runner.should_receive(:run).with(['spec'], hash_including(:message => 'Running all specs')) { true }

      subject.run_all
    end

    it "throws task_has_failed if specs don't passed" do
      runner.should_receive(:run) { false }

      expect { subject.run_all }.to throw_symbol :task_has_failed
    end

    it_should_behave_like 'clear failed paths'
  end

  describe '#reload' do
    it_should_behave_like 'clear failed paths'
  end

  describe '#run_on_changes' do
    before { inspector.stub(:clean => ['spec/foo']) }

    it 'runs rspec with paths' do
      runner.should_receive(:run).with(['spec/foo']) { true }

      subject.run_on_changes(['spec/foo'])
    end

    context 'the changed specs pass after failing' do
      subject { described_class.new([], :all_after_pass => true) }

      it 'calls #run_all' do
        runner.should_receive(:run).with(['spec/foo']) { false }

        expect { subject.run_on_changes(['spec/foo']) }.to throw_symbol :task_has_failed

        runner.should_receive(:run).with(['spec/foo']) { true }
        subject.should_receive(:run_all)

        expect { subject.run_on_changes(['spec/foo']) }.to_not throw_symbol
      end

      context ':all_after_pass option is false' do
        subject { described_class.new([], :all_after_pass => false) }

        it "doesn't call #run_all" do
          runner.should_receive(:run).with(['spec/foo']) { false }

          expect { subject.run_on_changes(['spec/foo']) }.to throw_symbol :task_has_failed

          runner.should_receive(:run).with(['spec/foo']) { true }
          subject.should_not_receive(:run_all)

          expect { subject.run_on_changes(['spec/foo']) }.to_not throw_symbol
        end
      end
    end

    context 'the changed specs pass without failing' do
      it "doesn't call #run_all" do
        runner.should_receive(:run).with(['spec/foo']) { true }

        subject.should_not_receive(:run_all)

        subject.run_on_changes(['spec/foo'])
      end
    end

    it 'keeps failed spec and rerun them later' do
      subject = described_class.new([], :keep_failed => true, :all_after_pass => false)

      inspector.should_receive(:clean).with(['spec/bar']).and_return(['spec/bar'])
      runner.should_receive(:run).with(['spec/bar']) { false }

      expect { subject.run_on_changes(['spec/bar']) }.to throw_symbol :task_has_failed

      inspector.should_receive(:clean).with(['spec/foo', 'spec/bar']).and_return(['spec/foo', 'spec/bar'])
      runner.should_receive(:run).with(['spec/foo', 'spec/bar']) { true }

      subject.run_on_changes(['spec/foo'])

      inspector.should_receive(:clean).with(['spec/foo']).and_return(['spec/foo'])
      runner.should_receive(:run).with(['spec/foo']) { true }

      subject.run_on_changes(['spec/foo'])
    end

    it "throws task_has_failed if specs doesn't pass" do
      runner.should_receive(:run).with(['spec/foo']) { false }

      expect { subject.run_on_changes(['spec/foo']) }.to throw_symbol :task_has_failed
    end

    describe "#run_on_changes focus_on_failed" do
      before do
        FileUtils.mkdir_p('tmp')
        File.open('./tmp/rspec_guard_result', 'w') do |f|
          f.puts("./a_spec.rb:1\n./a_spec.rb:7")
        end
        @subject = described_class.new([], :focus_on_failed => true, :keep_failed => true, :all_after_pass => true)
        @subject.last_failed = true

        inspector.stub(:clean){|ary| ary}
      end

      it "switches focus if a single spec changes" do
        runner.should_receive(:run).with(['b_spec.rb']).and_return(false)
        lambda { @subject.run_on_changes(['b_spec.rb']) }.should throw_symbol(:task_has_failed)
      end

      it "keeps focus if a single spec remains" do
        runner.should_receive(:run).with(['./a_spec.rb:1', './a_spec.rb:7']) { false }
        lambda { @subject.run_on_changes(['a_spec.rb']) }.should throw_symbol(:task_has_failed)
      end

      it "keeps focus if random stuff changes" do
        runner.should_receive(:run).with(['./a_spec.rb:1', './a_spec.rb:7']) { false }
        lambda { @subject.run_on_changes(['bob.rb','bill.rb']) }.should throw_symbol(:task_has_failed)
      end

      it "reruns the tests on the file if keep_failed is true and focused tests pass" do
        # explanation of test:
        #
        # If we detect any change, we first check the last rspec failure, we attempt to focus.
        # As soon as that passes we run all the specs that failed up until now
        #

        runner.should_receive(:run).with(['./a_spec.rb:1', './a_spec.rb:7']) { true }
        runner.should_receive(:run).with(['./a_spec.rb', './b_spec']) { true }
        runner.should_receive(:run).with(['spec'], :message => "Running all specs") { true }

        @subject.run_on_changes(['./a_spec.rb','./b_spec'])
      end
    end
  end
end

