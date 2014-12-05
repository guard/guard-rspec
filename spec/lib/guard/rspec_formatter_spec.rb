require "guard/rspec_formatter"

RSpec.describe Guard::RSpecFormatter do
  describe "::TEMPORARY_FILE_PATH" do
    subject { Pathname.new(described_class::TEMPORARY_FILE_PATH) }
    it { is_expected.to be_relative }
  end

  describe "#write_summary" do
    let(:writer) do
      StringIO.new
    end

    let(:formatter) do
      described_class.new(StringIO.new).tap do |formatter|
        allow(formatter).to receive(:_write) do |&block|
          block.call writer
        end
      end
    end

    let(:result) do
      writer.rewind
      writer.read
    end

    context "without stubbed IO" do
      let(:formatter) do
        described_class.new(StringIO.new)
      end

      it "creates temporary file and and writes to it" do
        file = File.expand_path(described_class::TEMPORARY_FILE_PATH)

        expect(FileUtils).to receive(:mkdir_p).
          with(File.dirname(file)) {}

        expect(File).to receive(:open).
          with(file, "w") do |_, _, &block|
          block.call writer
        end

        formatter.write_summary(123, 1, 2, 3)
      end
    end

    context "with failures" do
      let(:spec_filename) { "failed_location_spec.rb" }

      let(:failed_example) do
        double(
          execution_result: { status: "failed" },
          metadata: { location: spec_filename }
        )
      end

      def expected_output(spec_filename)
        /^3 examples, 1 failures in 123\.0 seconds\n#{spec_filename}\n$/
      end

      it "writes summary line and failed location in tmp dir" do
        allow(formatter).to receive(:examples) { [failed_example] }
        formatter.write_summary(123, 3, 1, 0)
        expect(result).to match expected_output(spec_filename)
      end

      it "writes only uniq filenames out" do
        allow(formatter).to receive(:examples).
          and_return([failed_example, failed_example])

        formatter.write_summary(123, 3, 1, 0)
        expect(result).to match expected_output(spec_filename)
      end

      context "for rspec 3" do
        let(:notification) do
          Struct.new(:duration, :example_count, :failure_count, :pending_count).
            new(123, 3, 1, 0)
        end
        before do
          allow(formatter.class).to receive(:rspec_3?).and_return(true)
        end

        it "writes summary line and failed location" do
          allow(formatter).to receive(:examples) { [failed_example] }
          formatter.dump_summary(notification)
          expect(result).to match expected_output(spec_filename)
        end
      end
    end

    it "should find the spec file for shared examples" do
      metadata = {
        location: "./spec/support/breadcrumbs.rb:75",
        example_group: { location: "./spec/requests/breadcrumbs_spec.rb:218" }
      }

      result = described_class.extract_spec_location(metadata)
      expect(result).to start_with "./spec/requests/breadcrumbs_spec.rb"
    end

    # Skip location because of rspec issue
    # https://github.com/rspec/rspec-core/issues/1243
    it "returns only the spec file without line number for shared examples" do
      metadata = {
        location: "./spec/support/breadcrumbs.rb:75",
        example_group: { location: "./spec/requests/breadcrumbs_spec.rb:218" }
      }
      expect(described_class.extract_spec_location(metadata)).
        to eq "./spec/requests/breadcrumbs_spec.rb"
    end

    context "when a shared examples has no location" do
      it "should return location of the root spec" do
        metadata = {
          location: "./spec/support/breadcrumbs.rb:75",
          example_group: {}
        }

        expect(STDERR).to receive(:puts).
          with("no spec file found for #{metadata[:location]}") {}

        expect(described_class.extract_spec_location(metadata)).
          to eq metadata[:location]
      end
    end

    context "with only success" do
      it "notifies success" do
        formatter.write_summary(123, 3, 0, 0)
        expect(result).to match /^3 examples, 0 failures in 123\.0 seconds\n$/
      end
    end

    context "with pending" do
      it "notifies pending too" do
        formatter.write_summary(123, 3, 0, 1)
        expect(result).to match(
          /^3 examples, 0 failures \(1 pending\) in 123\.0 seconds\n$/
        )
      end
    end
  end
end
