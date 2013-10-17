require 'spec_helper'

describe Guard::RSpec::Inspector do
  let(:options) { { } }
  let(:inspector) { Guard::RSpec::Inspector.new(options) }
  before { Guard::UI.stub(:warning) }

  describe '.initialize' do
    it "sets empty failed paths" do
      expect(inspector.failed_paths).to be_empty
    end
  end

  describe "#paths" do
    let(:paths) { %w[spec/lib/guard/rspec/inspector_spec.rb] }

    it "returns spec paths if no args" do
      expect(inspector.paths).to eq %w[spec]
    end

    context "with custom spec_paths" do
      let(:options) { { spec_paths: %w[custom_spec] } }

      it "returns custom spec paths if no args" do
        expect(inspector.paths).to eq %w[custom_spec]
      end

      it "returns spec path if given as argument" do
        expect(inspector.paths(%w[custom_spec])).to eq %w[custom_spec]
      end
    end

    it "returns new paths" do
      expect(inspector.paths(paths)).to eq paths
    end

    it "returns uniq new paths" do
      expect(inspector.paths(paths + paths)).to eq paths
    end

    it "returns compact new paths" do
      expect(inspector.paths(paths + [nil])).to eq paths
    end

    it "returns only rspec file" do
      expect(inspector.paths(paths + %w[foo])).to eq paths
    end

    it "returns spec path if given as argument" do
      expect(inspector.paths(%w[spec])).to eq %w[spec]
    end

    context "with focused paths" do
      before {
        FileUtils.mkdir_p('tmp')
        File.open(Guard::RSpec::Inspector::FOCUSED_FILE_PATH,'w') { |f|
          f.puts 'spec/lib/guard/rspec/command_spec.rb'
        }
      }

      it "returns them" do
        expect(inspector.paths(paths)).to eq %w[spec/lib/guard/rspec/command_spec.rb]
      end
    end

    context "without focused paths" do
      it "returns new paths" do
        expect(inspector.paths(paths)).to eq paths
      end
    end

    context "with keep_failed options and failed_paths" do
      let(:options) { { keep_failed: true } }
      let(:failed_paths) { %w[spec/lib/guard/rspec/command_spec.rb] }
      before { inspector.failed_paths = failed_paths }

      it "returns failed paths alongs new paths" do
        expect(inspector.paths(paths)).to eq failed_paths + paths
      end

      it "adds new paths to failed_paths" do
        inspector.paths(paths)
        expect(inspector.failed_paths).to eq failed_paths + paths
      end
    end
  end

  describe "#clear_paths" do
    before { inspector.failed_paths = %w[failed_path1 failed_path2] }

    it "clears all failed_paths if no args" do
      inspector.clear_paths
      expect(inspector.failed_paths).to be_empty
    end

    it "clears given failed_path" do
      inspector.clear_paths(%w[failed_path1 failed_path3])
      expect(inspector.failed_paths).to eq %w[failed_path2]
    end
  end

end
