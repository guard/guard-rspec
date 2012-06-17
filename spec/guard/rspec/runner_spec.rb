require 'spec_helper'

describe Guard::RSpec::Runner do
  subject { described_class.new }

  before do
    described_class.any_instance.stub(:failure_exit_code_supported? => true)
  end

  describe '.initialize' do
    it 'sets rspec_version' do
      described_class.new.rspec_version.should_not be_nil
    end

    describe 'shows warnings for deprecated options' do
      [:color, :drb, [:fail_fast, 'fail-fast'], [:formatter, 'format']].each do |option|
        key, value = option.is_a?(Array) ? option : [option, option.to_s]
        it "outputs deprecation warning for :#{key} option" do
          Guard::UI.should_receive(:info).with(
            "DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line " <<
            %(argument "--#{value}" to RSpec with the :cli option.)
          ).ordered
          described_class.new(key => 'foo')
        end
      end
    end
  end

  describe '#run' do
    context 'when passed an empty paths list' do
      it 'returns false' do
        subject.run([]).should be_false
      end
    end

    context 'in a folder without Bundler' do
      before do
        Dir.stub(:pwd).and_return(@fixture_path.join('empty'))
      end

      it 'runs with RSpec 2 and without bundler' do
        subject.should_receive(:system).with(
          "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
          '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
        ).and_return(true)

        subject.run(['spec'])
      end
    end

    context 'in RSpec 2 folder with Bundler' do
      before do
        Dir.stub(:pwd).and_return(@fixture_path.join('rspec2'))
      end

      it 'runs with RSpec 2 and with Bundler' do
        subject.should_receive(:system).with(
          "bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
          '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
        ).and_return(true)

        subject.run(['spec'])
      end

      describe 'notification' do
        it 'notifies when RSpec fails to execute' do
          subject.should_receive(:rspec_command) { "`exit 1`" }
          Guard::Notifier.should_receive(:notify).with(
            'Failed', :title => 'RSpec results', :image => :failed, :priority => 2
          )

          subject.run(['spec'])
        end

        context 'using DRb' do
          subject { described_class.new(:cli => '--drb') }

          let(:service) {
            service_double = double
            subject.should_receive(:drb_service) { |port|
              service_double.stub(:port) { port }
              service_double
            }

            service_double
          }

          context 'RSpec 1' do
            it 'returns false when RSpec fails to execute' do
              service.should_receive(:run) { false }

              subject.run(['spec']).should be_false
            end
            it 'returns true when RSpec succeeds to execute' do
              service.should_receive(:run) { true }

              subject.run(['spec']).should be_true
            end
          end

          context 'RSpec 2' do
            it 'returns false when RSpec fails to execute' do
              service.should_receive(:run) { 1 }

              subject.run(['spec']).should be_false
            end
            it 'returns true when RSpec succeeds to execute' do
              service.should_receive(:run) { 0 }

              subject.run(['spec']).should be_true
            end
          end

          it 'does not notify when RSpec fails to execute' do
            service.should_receive(:run) { 1 }
            Guard::Notifier.should_not_receive(:notify)

            subject.run(['spec'])
          end

          it 'falls back to the command runner with an inactive server' do
            service.should_receive(:run).and_raise(DRb::DRbConnError)
            subject.should_receive(:run_via_shell)

            subject.run(['spec'])
          end

          it 'defaults to DRb port 8989' do
            service.should_receive(:run) { 0 }
            subject.run(['spec'])
            service.port.should == 8989
          end

          it 'honors RSPEC_DRB' do
            ENV['RSPEC_DRB'] = '12345'
            service.should_receive(:run) { 0 }
            subject.run(['spec'])
            service.port.should == 12345
          end

          it 'honors --drb-port' do
            service.should_receive(:run) { 0 }
            subject.run(['spec'], cli: '--drb --drb-port 2222')
            service.port.should == 2222
          end
        end

        it 'does not notify that RSpec failed when the specs failed' do
          subject.should_receive(:rspec_command) { "`exit 2`" }
          Guard::Notifier.should_not_receive(:notify)

          subject.run(['spec'])
        end

        it 'does not notify that RSpec failed when the specs pass' do
          subject.should_receive(:rspec_command) { "`exit 0`" }
          Guard::Notifier.should_not_receive(:notify)

          subject.run(['spec'])
        end
      end

      describe 'options' do
        describe 'as parameters override @options' do
          subject { described_class.new(:cli => '--color') }

          it 'runs with rvm exec' do
            subject.should_receive(:system).with(
              'bundle exec rspec --format doc ' <<
              "-r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
              '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
            ).and_return(true)

            subject.run(['spec'], :cli => '--format doc')
          end
        end

        describe ':message is printed' do
          subject { described_class.new(:cli => '--color') }

          it 'runs with rvm exec' do
            ::Guard::UI.should_receive(:info).with('Foo Bar', :reset => true)
            subject.should_receive(:system).and_return(true)

            subject.run(['spec'], :message => 'Foo Bar')
          end
        end

        describe ':rvm' do
          context ":rvm => ['1.8.7', '1.9.2']" do
            subject { described_class.new(:rvm => ['1.8.7', '1.9.2']) }

            it 'runs with rvm exec' do
              subject.should_receive(:system).with(
                'rvm 1.8.7,1.9.2 exec bundle exec rspec -f progress ' <<
                "-r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end
        end

        describe ':cli' do
          context ":cli => '--color --drb --fail-fast'" do
            subject { described_class.new(:cli => '--color --drb --fail-fast') }

            it 'runs with CLI options passed to RSpec' do
              subject.should_receive(:system).with(
                'bundle exec rspec --color --drb --fail-fast -f progress ' <<
                "-r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end

          it 'use progress formatter by default' do
            subject.should_receive(:system).with(
              "bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
              '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
            ).and_return(true)

            subject.run(['spec'])
          end

          context ":cli => '-f doc'" do
            subject { described_class.new(:cli => '-f doc') }

            it 'respects formatter passed in CLI options to RSpec' do
              subject.should_receive(:system).with(
                "bundle exec rspec -f doc -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end

          context ":cli => '-fdoc'" do
            subject { described_class.new(:cli => '-fdoc') }

            it 'respects formatter passed in CLI options to RSpec' do
              subject.should_receive(:system).with(
                "bundle exec rspec -fdoc -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end

          context ":cli => '--format doc'" do
            subject { described_class.new(:cli => '--format doc') }

            it 'respects formatter passed in CLI options to RSpec' do
              subject.should_receive(:system).with(
                "bundle exec rspec --format doc -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end

          context ":cli => '--format=doc'" do
            subject { described_class.new(:cli => '--format=doc') }

            it 'respects formatter passed in CLI options to RSpec' do
              subject.should_receive(:system).with(
                "bundle exec rspec --format=doc -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end
        end

        describe ':bundler' do
          context ':bundler => false' do
            subject { described_class.new(:bundler => false) }

            it 'runs without Bundler' do
              subject.should_receive(:system).with(
                "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end
        end

        describe ':binstubs' do
          context ':bundler => false, :binstubs => true' do
            subject { described_class.new(:bundler => false, :binstubs => true) }

            it 'runs without Bundler and binstubs' do
              subject.should_receive(:system).with(
                "rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end

          context ':bundler => true, :binstubs => true' do
            subject { described_class.new(:bundler => true, :binstubs => true) }

            it 'runs with Bundler and binstubs' do
              subject.should_receive(:system).with(
                "bundle exec bin/rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end
        end

        describe ':notification' do
          context ':notification => false' do
            subject { described_class.new(:notification => false) }

            it 'runs without notification formatter' do
              subject.should_receive(:system).with(
                'bundle exec rspec --failure-exit-code 2 spec'
              ).and_return(true)

              subject.run(['spec'])
            end

            it "doesn't notify when specs fails" do
              subject.should_receive(:system) { mock('res', :success? => false, :exitstatus => 2) }
              Guard::Notifier.should_not_receive(:notify)

              subject.run(['spec'])
            end
          end
        end

        describe ':turnip' do
          context ':turnip => true' do
            subject { described_class.new(:turnip => true) }

            it 'runs with Turnip support enabled' do
              subject.should_receive(:system).with(
                "bundle exec rspec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_rspec.rb')} " <<
                '-f Guard::RSpec::Formatter::NotificationRSpec --out /dev/null --failure-exit-code 2 -r turnip/rspec spec'
              ).and_return(true)

              subject.run(['spec'])
            end
          end
        end
      end
    end

    context 'in RSpec 1 folder with Bundler' do
      before do
        Dir.stub(:pwd).and_return(@fixture_path.join('rspec1'))
        described_class.any_instance.stub(:failure_exit_code_supported? => false)
      end

      it 'runs with RSpec 1 and with bundler' do
        subject.should_receive(:system).with(
          "bundle exec spec -f progress -r #{@lib_path.join('guard/rspec/formatters/notification_spec.rb')} " <<
          '-f Guard::RSpec::Formatter::NotificationSpec:/dev/null spec'
        ).and_return(true)

        subject.run(['spec'])
      end
    end
  end

  describe '#rspec_version' do
    it ':version option sets the @rspec_version' do
      described_class.new(:version => 1).rspec_version.should be 1
    end

    context 'in empty folder' do
      before { Dir.stub(:pwd).and_return(@fixture_path.join('empty')) }

      it 'sets RSpec 2 because cannot determine version' do
        subject.rspec_version.should be 2
      end
    end

    context 'in RSpec 1 folder with Bundler' do
      before { Dir.stub(:pwd).and_return(@fixture_path.join('bundler_only_rspec1')) }

      it 'sets RSpec 1 from Bundler' do
        subject.rspec_version.should be 1
      end
    end

    context 'in RSpec 2 folder with Bundler' do
      before { Dir.stub(:pwd).and_return(@fixture_path.join('bundler_only_rspec2')) }

      it 'sets RSpec 2 from Bundler' do
        subject.rspec_version.should be 2
      end
    end

    context 'in RSpec 1 folder without Bundler' do
      before { Dir.stub(:pwd).and_return(@fixture_path.join('rspec1')) }

      it 'sets RSpec 1 from spec_helper.rb' do
        subject.rspec_version.should be 1
      end
    end

    context 'in RSpec 2 folder without Bundler' do
      before { Dir.stub(:pwd).and_return(@fixture_path.join('rspec2')) }

      it 'sets RSpec 2 from spec_helper.rb' do
        subject.rspec_version.should be 2
      end
    end
  end

  describe '#parsed_or_default_formatter' do
    context '.rspec file exists' do
      before do
        Dir.stub(:pwd).and_return(@fixture_path)
      end

      context 'and includes a --format option' do
        before do
          File.stub(:read).and_return("--colour\n--format RSpec::Instafail")
        end

        it 'returns the formatter from .rspec file' do
          subject.parsed_or_default_formatter.should eq '-f RSpec::Instafail'
        end
      end

      context 'but doesn\'t include a --format option' do
        before do
          File.stub(:read).and_return("--colour")
        end

        it 'returns progress formatter' do
          subject.parsed_or_default_formatter.should eq '-f progress'
        end
      end
    end

    context '.rspec file doesn\'t exists' do
      before { File.stub(:exist?).and_return(false) }

      it 'returns progress formatter' do
        subject.parsed_or_default_formatter.should eq '-f progress'
      end
    end
  end

end
