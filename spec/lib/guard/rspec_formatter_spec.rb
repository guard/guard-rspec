require "guard/rspec_formatter"

RSpec.describe Guard::RSpecFormatter do
  describe "#dump_summary" do
    def rspec_summary_args(*args)
      return args unless ::RSpec::Core::Version::STRING.start_with?("3.")

      n = Struct.new(:duration, :example_count, :failure_count, :pending_count)
      [n.new(*args)]
    end

    # Returns a Hash that throws an error if a key is accessed that isn't set.
    def hash_double(attrs)
      dbl = Hash.new{|hsh, key| raise "Missing key: #{key.inspect}." }
      dbl.merge(attrs)
    end

    let(:example_dump_summary_args) { rspec_summary_args(123, 3, 1, 0) }
    let(:summary_with_no_failures) { rspec_summary_args(123, 3, 0, 0) }
    let(:summary_with_only_pending) { rspec_summary_args(123, 3, 0, 1) }

    let(:failed_example) do
      result =
        if ::RSpec::Core::Version::STRING.start_with?("3.")
          double(status: "failed")
        else
          { status: "failed" }
        end

      double(execution_result: result, metadata: { location: spec_filename })
    end

    let(:writer) do
      StringIO.new
    end

    let(:stub_formatter) { true }

    let(:formatter) do
      described_class.new(StringIO.new).tap do |formatter_stub|
        if stub_formatter
          allow(formatter_stub).to receive(:_write) do |&block|
            block.call writer
          end
        end
      end
    end

    let(:result) do
      writer.rewind
      writer.read
    end

    context "without stubbed IO" do
      let(:stub_formatter) { false }

      around do |example|
        env_var = "GUARD_RSPEC_RESULTS_FILE"
        old, ENV[env_var] = ENV[env_var], "foobar.txt"
        example.run
        ENV[env_var] = old
      end

      it "creates temporary file and and writes to it" do
        file = File.expand_path("foobar.txt")

        expect(FileUtils).to receive(:mkdir_p).
          with(File.dirname(file)) {}

        expect(File).to receive(:open).
          with(file, "w") do |_, _, &block|
          block.call writer
        end

        formatter.dump_summary(*example_dump_summary_args)
      end

      context "when writing file fails" do
        it "outputs an error" do
          allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)
          expect do
            formatter.dump_summary(*example_dump_summary_args)
          end.to raise_error(Errno::EACCES)
        end
      end

      context "when writer fails" do
        it "outputs an error" do
          allow(FileUtils).to receive(:mkdir_p).and_raise(TypeError, "foo")
          expect do
            formatter.dump_summary(*example_dump_summary_args)
          end.to raise_error(TypeError, "foo")
        end
      end
    end

    context "with failures" do
      let(:spec_filename) { "failed_location_spec.rb" }

      def expected_output(spec_filename)
        /^3 examples, 1 failures in 123\.0 seconds\n#{spec_filename}\n$/
      end

      it "writes summary line and failed location in tmp dir" do
        allow(formatter).to receive(:examples) { [failed_example] }
        formatter.dump_summary(*example_dump_summary_args)
        expect(result).to match expected_output(spec_filename)
      end

      it "writes only uniq filenames out" do
        allow(formatter).to receive(:examples).
          and_return([failed_example, failed_example])

        formatter.dump_summary(*example_dump_summary_args)
        expect(result).to match expected_output(spec_filename)
      end

      let(:notification) { example_dump_summary_args }

      it "writes summary line and failed location" do
        allow(formatter).to receive(:examples) { [failed_example] }
        formatter.dump_summary(*notification)
        expect(result).to match expected_output(spec_filename)
      end
    end

    it "should find the spec file for shared examples" do
      metadata = hash_double(
        location: "./spec/support/breadcrumbs.rb:75",
        example_group: { location: "./spec/requests/breadcrumbs_spec.rb:218" }
      )

      result = described_class.extract_spec_location(metadata)
      expect(result).to start_with "./spec/requests/breadcrumbs_spec.rb"
    end

    # Skip location because of rspec issue
    # https://github.com/rspec/rspec-core/issues/1243
    it "returns only the spec file without line number for shared examples" do
      metadata = hash_double(
        location: "./spec/support/breadcrumbs.rb:75",
        example_group: { location: "./spec/requests/breadcrumbs_spec.rb:218" }
      )
      expect(described_class.extract_spec_location(metadata)).
        to eq "./spec/requests/breadcrumbs_spec.rb"
    end

    context "when a shared examples has no location" do
      it "should return location of the root spec" do
        metadata = hash_double(
          location: "./spec/support/breadcrumbs.rb:75",
          example_group: {}
        )

        expect(STDERR).to receive(:puts).
          with("no spec file location in #{metadata.inspect}")

        expect(described_class.extract_spec_location(metadata)).
          to eq metadata[:location]
      end
    end

    context "when a shared examples are nested" do
      it "should return location of the root spec" do
        metadata = hash_double(
          location: "./spec/support/breadcrumbs.rb:75",
          example_group: {
            example_group: {
              location: "./spec/requests/breadcrumbs_spec.rb:218"
            }
          }
        )

        expect(described_class.extract_spec_location(metadata)).
          to eq "./spec/requests/breadcrumbs_spec.rb"
      end
    end

    context "when RSpec 3.0 metadata is present" do
      it "should return location of the root spec" do
        metadata = hash_double(
          location: "./spec/support/breadcrumbs.rb:75",
          parent_example_group: {
            location: "./spec/requests/breadcrumbs_spec.rb:218"
          }
        )

        expect(described_class.extract_spec_location(metadata)).
          to eq "./spec/requests/breadcrumbs_spec.rb"
      end
    end

    context "with only success" do
      it "notifies success" do
        formatter.dump_summary(*summary_with_no_failures)
        expect(result).to match /^3 examples, 0 failures in 123\.0 seconds\n$/
      end
    end

    context "with pending" do
      it "notifies pending too" do
        formatter.dump_summary(*summary_with_only_pending)
        expect(result).to match(
          /^3 examples, 0 failures \(1 pending\) in 123\.0 seconds\n$/
        )
      end
    end
  end
end
