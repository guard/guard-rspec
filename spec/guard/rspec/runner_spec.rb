require 'spec_helper'

describe Guard::RSpec::Runner do
  subject { described_class.new }
  describe ".initialize" do
    it "sets rspec_version" do
      described_class.new.rspec_version.should_not be_nil
    end

    describe "shows warnings for deprecated options" do
      [:color, :drb, [:fail_fast, 'fail-fast'], [:formatter, 'format']].each do |option|
        key, value = option.is_a?(Array) ? option : [option, option.to_s]
        it "outputs deprecation warning for :#{key} option" do
          Guard::UI.should_receive(:info).with(%{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value}" to RSpec with the :cli option.}).ordered
          described_class.new(key => 'foo')
        end
      end
    end
  end

  describe ".run" do
    context "when passed an empty paths list" do
      it "returns false" do
        subject.run([]).should be_false
      end
    end

    context "in a folder without Bundler" do
      before do
        Dir.stub(:pwd).and_return(@fixture_path.join("empty"))
        subject.set_rspec_version
      end

      it "runs with RSpec 2 and without bundler" do
        subject.should_receive(:system).with(
          "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
        ).and_return(true)
        subject.run(["spec"])
      end
    end

    context "in RSpec 2 folder with Bundler" do
      before do
        Dir.stub(:pwd).and_return(@fixture_path.join("rspec2"))
        subject.set_rspec_version
      end

      it "runs with RSpec 2 and with Bundler" do
        subject.should_receive(:system).with(
          "bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
        ).and_return(true)
        subject.run(["spec"])
      end

      describe "notification" do
        before(:each) do
          # This was introduced in RSpec 2.7, we assume it here for the purpose of these examples
          subject.stub(:failure_exit_code_supported? => true)
        end

        it "notifies when RSpec fails to execute" do
          subject.should_receive(:rspec_command) { |paths, options| "`exit 1`" }

          Guard::Notifier.should_receive(:notify).with("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
          subject.run(["spec"])
        end

        it "does not notify notifies when RSpec fails to execute and using drb" do
          subject.should_receive(:rspec_command) { |paths, options| "`exit 1`" }

          Guard::Notifier.should_not_receive(:notify).with("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
          subject.run(["spec"], :cli => "--drb")
        end

        it "does not notify that RSpec failed when the specs failed" do        
          subject.should_receive(:rspec_command) { |paths, options| "`exit 2`" }

          Guard::Notifier.should_not_receive(:notify).with("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
          subject.run(["spec"])
        end

        it "does not notify that RSpec failed when the specs pass" do
          subject.should_receive(:rspec_command) { |paths, options| "`exit 0`" }

          Guard::Notifier.should_not_receive(:notify).with("Failed", :title => "RSpec results", :image => :failed, :priority => 2)
          subject.run(["spec"])
        end
      end

      describe "options" do
        describe ":rvm" do
          it "runs with rvm exec" do
            subject.should_receive(:system).with(
              "rvm 1.8.7,1.9.2 exec bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :rvm => ['1.8.7', '1.9.2'])
          end
        end

        describe ":cli" do
          it "runs with CLI options passed to RSpec" do
            subject.should_receive(:system).with(
            "bundle exec rspec --color --drb --fail-fast -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :cli => "--color --drb --fail-fast")
          end

          it "sets progress formatter by default if no formatter is passed in CLI options to RSpec" do
            subject.should_receive(:system).with(
            "bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"])
          end

          it "respects formatter passed in CLI options to RSpec" do
            subject.should_receive(:system).with(
            "bundle exec rspec -f doc -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :cli => "-f doc")
          end

          it "respects formatter passed in CLI options to RSpec, using the '=' syntax" do
            subject.should_receive(:system).with(
            "bundle exec rspec --format=doc -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :cli => "--format=doc")
          end
        end

        describe ":bundler" do
          it "runs without Bundler with bundler option to false" do
            subject.should_receive(:system).with(
              "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :bundler => false)
          end
        end

        describe ":binstubs" do
          it "runs without Bundler with binstubs option to true and bundler option to false" do
            subject.should_receive(:system).with(
              "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :bundler => false, :binstubs => true)
          end
          it "runs with Bundler and binstubs with bundler option to true and binstubs option to true" do
            subject.should_receive(:system).with(
              "bundle exec bin/rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :bundler => true, :binstubs => true)
          end
          it "runs with Bundler and binstubs with bundler option unset and binstubs option to true" do
            subject.should_receive(:system).with(
              "bundle exec bin/rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :binstubs => true)
          end
          it "runs with Bundler and binstubs with bundler option unset, binstubs option to true and all_after_pass option to true" do
            subject.should_receive(:system).with(
              "bundle exec bin/rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :binstubs => true, :all_after_pass => true)
          end
          it "runs with Bundler and binstubs with bundler option unset, binstubs option to true and all_on_start option to true" do
            subject.should_receive(:system).with(
              "bundle exec bin/rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :binstubs => true, :all_on_start => true)
          end
          it "runs with Bundler and binstubs with bundler option unset, binstubs option to true, all_on_start option to true and all_after_pass option to true" do
            subject.should_receive(:system).with(
              "bundle exec bin/rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :binstubs => true, :all_after_pass => true, :all_on_start => true)
          end
        end

        describe ":notification" do
          it "runs without notification formatter with notification option to false" do
            subject.should_receive(:system).with(
              "bundle exec rspec -f progress --failure-exit-code 2 spec"
            ).and_return(true)
            subject.run(["spec"], :notification => false)
          end

          it "does not notify when RSpec fails to execute" do
            subject.should_receive(:system).and_return(nil)
            system("`exit 2`") # prime the $? variable
            Guard::Notifier.should_not_receive(:notify)
            subject.run(["spec"], :notification => false)
          end
        end

        describe "deprecated options" do
          [:color, :drb, :fail_fast, [:formatter, "format"]].each do |option|
            key, value = option.is_a?(Array) ? option : [option, option.to_s]
            it "outputs deprecation warning for :#{key} option" do
              Guard::UI.should_receive(:info).with("Running: spec", { :reset => true }).ordered
              Guard::UI.should_receive(:info).with(%{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value.gsub('_', '-')}" to RSpec with the :cli option.}).ordered
              subject.stub(:system).and_return(true)
              subject.run(["spec"], key => false)
            end
          end
        end
      end
    end

    context "in RSpec 1 folder with Bundler" do
      before do
        Dir.stub(:pwd).and_return(@fixture_path.join("rspec1"))
        subject.set_rspec_version
      end

      it "runs with RSpec 1 and with bundler" do
        subject.should_receive(:system).with(
          "bundle exec spec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_spec.rb')} -f Guard::RSpec::Formatter::NotificationSpec:/dev/null spec"
        ).and_return(true)
        subject.run(["spec"])
      end
    end
  end

  describe ".set_rspec_version" do
    it "uses version option first" do
      subject.set_rspec_version(:version => 1)
      subject.rspec_version.should == 1
    end

    context "in empty folder" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("empty")) }

      it "sets RSpec 2 because cannot determine version" do
        subject.set_rspec_version
        subject.rspec_version.should == 2
      end
    end

    context "in RSpec 1 folder with Bundler" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("bundler_only_rspec1")) }

      it "sets RSpec 1 from Bundler" do
        subject.set_rspec_version
        subject.rspec_version.should == 1
      end
    end

    context "in RSpec 2 folder with Bundler" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("bundler_only_rspec2")) }

      it "sets RSpec 2 from Bundler" do
        subject.set_rspec_version
        subject.rspec_version.should == 2
      end
    end

    context "in RSpec 1 folder without Bundler" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("rspec1")) }

      it "sets RSpec 1 from spec_helper.rb" do
        subject.set_rspec_version
        subject.rspec_version.should == 1
      end
    end

    context "in RSpec 2 folder without Bundler" do
      before(:each) { Dir.stub(:pwd).and_return(@fixture_path.join("rspec2")) }

      it "sets RSpec 2 from spec_helper.rb" do
        subject.set_rspec_version
        subject.rspec_version.should == 2
      end
    end
  end

end
