require 'spec_helper'

describe Guard::RSpec::Inspector do
  describe ".new" do
    it "returns the singleton (refactoring step)" do
      Guard::RSpec::Inspector.new.should be == Guard::RSpec::Inspector
    end
  end

  describe ".clean" do
    before do
      subject.excluded = nil
      subject.spec_paths = ["spec"]
    end

    it "accept a string as spec_paths" do
      subject.spec_paths ="test"
      subject.spec_paths.should == ["test"]
    end

    it "accept an array as spec_paths" do
      subject.spec_paths =["test"]
      subject.spec_paths.should == ["test"]
    end

    it "removes non-spec files" do
      subject.clean(["spec/guard/rspec_spec.rb", "bob.rb"]).should == ["spec/guard/rspec_spec.rb"]
    end

    it "removes spec-looking but non-existing files" do
      subject.clean(["spec/guard/rspec_spec.rb", "bob_spec.rb"]).should == ["spec/guard/rspec_spec.rb"]
    end

    it "removes spec-looking but non-existing files (2)" do
      subject.clean(["spec/guard/rspec/version_spec.rb"]).should == []
    end

    it "keeps spec folder path" do
      subject.clean(["spec/guard/rspec_spec.rb", "spec/models"]).should == ["spec/guard/rspec_spec.rb", "spec/models"]
    end

    it "removes duplication" do
      subject.clean(["spec", "spec"]).should == ["spec"]
    end

    it "removes spec folders included in other spec folders" do
      subject.clean(["spec/models", "spec"]).should == ["spec"]
    end

    it "removes spec files included in spec folders" do
      subject.clean(["spec/guard/rspec_spec.rb", "spec"]).should == ["spec"]
    end

    it "removes spec files included in spec folders (2)" do
      subject.clean(["spec/guard/rspec_spec.rb", "spec/guard/rspec/runner_spec.rb", "spec/guard/rspec"]).should == ["spec/guard/rspec_spec.rb", "spec/guard/rspec"]
    end

    describe 'excluded files' do
      context 'with a path to a single spec' do
        it 'ignores the one spec' do
          subject.excluded = 'spec/guard/rspec_spec.rb'
          subject.clean(['spec/guard/rspec_spec.rb']).should == []
        end
      end

      context 'with a glob' do
        it 'ignores files recursively' do
          subject.excluded = 'spec/guard/**/*'
          subject.clean(['spec/guard/rspec_spec.rb', 'spec/guard/rspec/runner_spec.rb']).should == []
        end
      end
    end

    describe 'spec paths' do
      context 'with an expanded spec path' do
        before { subject.spec_paths = ["spec", "spec/fixtures/other_spec_path"] }

        it "should clean paths not specified" do
          subject.clean(['clean_me/spec/cleaned_spec.rb', 'spec/guard/rspec/runner_spec.rb', 'spec/fixtures/other_spec_path/empty_spec.rb']).should == ['spec/guard/rspec/runner_spec.rb', 'spec/fixtures/other_spec_path/empty_spec.rb']
        end
      end
    end
  end
end
