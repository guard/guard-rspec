require 'spec_helper'

describe Guard::RSpec::Inspector do

  describe '.initialize' do
    it 'accepts an :exclude option that sets @excluded' do
      inspector1 = described_class.new(:exclude => 'spec/slow/*')

      inspector2 = described_class.new
      inspector2.excluded = 'spec/slow/*'

      inspector1.excluded.should eq inspector2.excluded
    end

    it 'accepts a :spec_paths option that sets @spec_paths' do
      inspector1 = described_class.new(:spec_paths => ['spec/slow'])

      inspector2 = described_class.new
      inspector2.spec_paths = ['spec/slow']

      inspector1.spec_paths.should eq inspector2.spec_paths
    end
  end

  describe '#excluded=' do
    it 'runs a glob on the given pattern' do
      subject.excluded = 'spec/slow/*'
      subject.excluded.should eq Dir['spec/slow/*']
    end
  end

  describe '#spec_paths=' do
    context 'given a string' do
      before { subject.spec_paths = 'test' }

      it 'returns an array' do
        subject.spec_paths.should eq ['test']
      end
    end

    context 'given an array' do
      before { subject.spec_paths = ['test'] }

      it 'returns an array' do
        subject.spec_paths.should eq ['test']
      end
    end
  end

  describe '#clean' do
    before do
      subject.excluded = nil
      subject.spec_paths = ['spec']
    end

    it 'removes non-spec files' do
      subject.clean(['spec/guard/rspec_spec.rb', 'bob.rb']).
      should eq ['spec/guard/rspec_spec.rb']
    end

    it 'removes spec-looking but non-existing files' do
      subject.clean(['spec/guard/rspec_spec.rb', 'bob_spec.rb']).
      should eq ['spec/guard/rspec_spec.rb']
    end

    it 'removes spec-looking but non-existing files (2)' do
      subject.clean(['spec/guard/rspec/version_spec.rb']).should be_empty
    end

    it 'keeps spec folder path' do
      subject.clean(['spec/guard/rspec_spec.rb', 'spec/models']).
      should eq ['spec/guard/rspec_spec.rb', 'spec/models']
    end

    it 'removes duplication' do
      subject.clean(['spec', 'spec']).should eq ['spec']
    end

    it 'removes spec folders included in other spec folders' do
      subject.clean(['spec/models', 'spec']).should eq ['spec']
    end

    it 'removes spec files included in spec folders' do
      subject.clean(['spec/guard/rspec_spec.rb', 'spec']).should eq ['spec']
    end

    it 'removes spec files included in spec folders (2)' do
      subject.clean([
        'spec/guard/rspec_spec.rb', 'spec/guard/rspec/runner_spec.rb',
        'spec/guard/rspec'
      ]).should eq ['spec/guard/rspec_spec.rb', 'spec/guard/rspec']
    end

    it 'keeps top-level specs' do
      subject.spec_paths = ['spec/fixtures/other_spec_path']
      subject.clean(['spec/fixtures/other_spec_path/empty_spec.rb']).
      should eq ['spec/fixtures/other_spec_path/empty_spec.rb']
    end

    it 'keeps spec files in symlink target' do
      subject.clean(['spec/fixtures/symlink_to_spec/rspec_spec.rb']).
      should eq ['spec/fixtures/symlink_to_spec/rspec_spec.rb']
    end

    describe 'excluded files' do
      context 'with a path to a single spec' do
        it 'ignores the one spec' do
          subject.excluded = 'spec/guard/rspec_spec.rb'
          subject.clean(['spec/guard/rspec_spec.rb']).should be_empty
        end
      end

      context 'with a glob' do
        it 'ignores files recursively' do
          subject.excluded = 'spec/guard/**/*'
          subject.clean(['spec/guard/rspec_spec.rb', 'spec/guard/rspec/runner_spec.rb']).should be_empty
        end
      end
    end

    describe 'spec paths' do
      context 'with an expanded spec path' do
        before { subject.spec_paths = ['spec', 'spec/fixtures/other_spec_path'] }

        it 'should clean paths not specified' do
          subject.clean([
            'clean_me/spec/cleaned_spec.rb', 'spec/guard/rspec/runner_spec.rb',
            'spec/fixtures/other_spec_path/empty_spec.rb'
          ]).should eq ['spec/guard/rspec/runner_spec.rb', 'spec/fixtures/other_spec_path/empty_spec.rb']
        end
      end
    end

    context "with spec_file_extension set to .spec.rb" do
      before { subject.spec_file_extension = '.spec.rb' }
      let(:files) { [
        'spec/fixtures/file_extensions/underscore_spec.rb',
        'spec/fixtures/file_extensions/dot.spec.rb'] }
      it "accepts .spec.rb files" do
        subject.clean(files).should == [files.last]
      end
    end

  end

end
