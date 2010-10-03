require 'spec_helper'

describe Guard::RSpec do
  subject { Guard::RSpec.new }
  
  describe "start" do
    it "should set rspec_version" do
      Guard::RSpec::Runner.should_receive(:set_rspec_version)
      subject.start
    end
  end
  
  describe "run_all" do
    it "should run all spec" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"], :message => "Running all specs")
      subject.run_all
    end
  end
  
  describe "run_on_change" do
    it "should run rspec with paths" do
      Guard::RSpec::Runner.should_receive(:run).with(["spec"])
      subject.run_on_change(["spec"])
    end
  end
  
end
