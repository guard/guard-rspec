require 'spec_helper'

describe Guard::RSpec::Runner do

  describe ".run" do
    context "when passed an empty paths list" do
      it "returns false" do
        subject.run([]).should be_false
      end
    end

    context "in a folder without Bundler" do
      before(:each) do
        Dir.stub(:pwd).and_return(@fixture_path.join("empty"))
        subject.set_rspec_version
      end

      it "runs with RSpec 2 and without bundler" do
        subject.should_receive(:system).with(
          "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f NotificationRSpec --out /dev/null spec"
        )
        subject.run(["spec"])
      end
    end

    context "in RSpec 2 folder with Bundler" do
      before(:each) do
        Dir.stub(:pwd).and_return(@fixture_path.join("rspec2"))
        subject.set_rspec_version
      end

      it "runs with RSpec 2 and with Bundler" do
        subject.should_receive(:system).with(
          "bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f NotificationRSpec --out /dev/null spec"
        )
        subject.run(["spec"])
      end

      describe "options" do
        describe ":rvm" do
          it "runs with rvm exec" do
            subject.should_receive(:system).with(
              "rvm 1.8.7,1.9.2 exec bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f NotificationRSpec --out /dev/null spec"
            )
            subject.run(["spec"], :rvm => ['1.8.7', '1.9.2'])
          end
        end

        describe ":cli" do
          it "runs with CLI options passed to RSpec" do
            subject.should_receive(:system).with(
            "bundle exec rspec --color --drb --fail-fast -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f NotificationRSpec --out /dev/null spec"
            )
            subject.run(["spec"], :cli => "--color --drb --fail-fast")
          end

          it "sets progress formatter by default if no formatter is passed in CLI options to RSpec" do
            subject.should_receive(:system).with(
            "bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f NotificationRSpec --out /dev/null spec"
            )
            subject.run(["spec"])
          end

          it "respects formatter passed in CLI options to RSpec" do
            subject.should_receive(:system).with(
            "bundle exec rspec -f doc -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f NotificationRSpec --out /dev/null spec"
            )
            subject.run(["spec"], :cli => "-f doc")
          end
        end

        describe ":bundler" do
          it "runs without Bundler with bundler option to false" do
            subject.should_receive(:system).with(
              "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} -f NotificationRSpec --out /dev/null spec"
            )
            subject.run(["spec"], :bundler => false)
          end
        end

        describe ":notification" do
          it "runs without notification formatter with notification option to false" do
            subject.should_receive(:system).with(
              "bundle exec rspec -f progress spec"
            )
            subject.run(["spec"], :notification => false)
          end
        end

        describe "deprecated options" do
          [:color, :drb, :fail_fast, [:formatter, "format"]].each do |option|
            key, value = option.is_a?(Array) ? option : [option, option.to_s]
            it "outputs deprecation warning for :#{key} option" do
              Guard::UI.should_receive(:info).with("Running: spec", { :reset => true }).ordered
              Guard::UI.should_receive(:info).with(%{DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{value.gsub('_', '-')}" to RSpec with the :cli option.}).ordered
              subject.stub(:system)
              subject.run(["spec"], key => false)
            end
          end
        end
      end
    end

    context "in RSpec 1 folder with Bundler" do
      before(:each) do
        Dir.stub(:pwd).and_return(@fixture_path.join("rspec1"))
        subject.set_rspec_version
      end

      it "runs with RSpec 1 and with bundler" do
        subject.should_receive(:system).with(
          "bundle exec spec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_spec.rb')} -f NotificationSpec:/dev/null spec"
        )
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
