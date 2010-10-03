require 'spec_helper'

describe Guard::RSpec::Runner do
  subject { Guard::RSpec::Runner}
  
  describe "run" do
    
    context "in empty folder" do
      before(:each) do
        Dir.stub(:pwd).and_return(@fixture_path.join("empty"))
        subject.set_rspec_version
      end
      
      it "should run with RSpec 2 and without bundler" do
        subject.should_receive(:system).with(
          "rspec --require #{@lib_path.join('guard/rspec/formatter/rspec2.rb')} --format RSpec2 --color spec"
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
          "bundle exec spec -f progress --require #{@lib_path.join('guard/rspec/formatter/rspec1.rb')} --format RSpec1:STDOUT --color spec"
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
