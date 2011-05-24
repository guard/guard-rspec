require 'spec_helper'

describe Guard::RSpec::Inspector do
  describe ".clean" do
    before do
      subject.excluded = nil
    end

    it "removes non-spec files" do
      subject.clean(["spec/guard/rspec_spec.rb", "bob.rb"]).should == ["spec/guard/rspec_spec.rb"]
    end

    it "removes spec-looking but non-existing files" do
      subject.clean(["spec/guard/rspec_spec.rb", "bob_spec.rb"]).should == ["spec/guard/rspec_spec.rb"]
    end

    it "removes spec-looking but non-existing files (2)" do
      subject.clean(["spec/guard/rspec/formatter_spec.rb"]).should == []
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
  end
end
