require 'spec_helper'

describe "integration test" do 

  describe "running a broken test" do 
    before do 
      FileUtils.rm_rf 'tmp'
      `rspec spec/fixtures/other_spec_path/broken.rb --require ./lib/guard/rspec/formatter.rb --format Guard::RSpec::Formatter`
    end

    it "should create the result file" do 
      File.exists?('tmp/rspec_guard_result').should == true
    end

    it "should have the correct failing tests in the result file" do 
      File.read('tmp/rspec_guard_result').should == "./spec/fixtures/other_spec_path/broken.rb:5\n./spec/fixtures/other_spec_path/broken.rb:12\n"
    end
  
  end

end
