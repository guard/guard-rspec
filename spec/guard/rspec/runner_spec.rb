require 'spec_helper'

describe Guard::RSpec::Runner do
  subject { Guard::RSpec::Runner }

  describe 'using_drb?' do
    it 'is true when DRB options is true' do
      subject.use_drb({:drb => true})
      subject.should be_using_drb
    end

    it 'is false when the DRB option is anything but true' do
      subject.use_drb({:drb => 'strawberry jam'})
      subject.should_not be_using_drb
    end
  end

  describe "run" do
    
    context "in empty folder" do
      before(:each) do
        Dir.stub(:pwd).and_return(@fixture_path.join("empty"))
        subject.set_rspec_version
      end
      
      it "should run with RSpec 2 and without bundler" do
        subject.should_receive(:system).with(
          "rspec --require #{@lib_path.join('guard/rspec/formatters/rspec_notify.rb')} --format RSpecNotify --color spec"
        )
        subject.run(["spec"])
      end
    end
    
    context "in RSpec 1 folder" do
      before(:each) do
        Dir.stub(:pwd).and_return(@fixture_path.join("rspec1"))
        subject.set_rspec_version
      end
      
      it "should run with RSpec 1 and with bundler" do
        subject.should_receive(:system).with(
          "bundle exec spec -f progress --require #{@lib_path.join('guard/rspec/formatters/spec_notify.rb')} --format SpecNotify:STDOUT --color spec"
        )
        subject.run(["spec"])
      end
    end
    
  end
  
  describe "set_rspec_version" do
    
    it "should use version option first" do
      subject.set_rspec_version(:version => 1)
      subject.rspec_version.should == 1
    end
    
    context "in empty folder" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("empty")) }
      
      it "should set RSpec 2 because cannot determine version" do
        subject.set_rspec_version
        subject.rspec_version.should == 2
      end
    end
    
    context "in RSpec 1 with bundler only folder" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("bundler_only_rspec1")) }
      
      it "should set RSpec 1 from Bundler" do
        subject.set_rspec_version
        subject.rspec_version.should == 1
      end
    end
    
    context "in RSpec 2 with bundler only folder" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("bundler_only_rspec2")) }
      
      it "should set RSpec 2 from Bundler" do
        subject.set_rspec_version
        subject.rspec_version.should == 2
      end
    end
    
    context "in RSpec 1" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("rspec1")) }
      
      it "should set RSpec 1 from spec_helper.rb" do
        subject.set_rspec_version
        subject.rspec_version.should == 1
      end
    end
    
    context "in RSpec 2" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("rspec2")) }
      
      it "should set RSpec 2 from spec_helper.rb" do
        subject.set_rspec_version
        subject.rspec_version.should == 2
      end
    end
  end
  
end
