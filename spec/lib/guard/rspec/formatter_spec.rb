require 'spec_helper.rb'
require 'guard/rspec/formatter'

describe Guard::RSpec::Formatter do
  describe '::TEMPORARY_FILE_PATH' do
    it 'is absolute path' do
      require 'pathname'
      temporary_file_path = described_class.const_get(:TEMPORARY_FILE_PATH)
      expect(Pathname.new(temporary_file_path).absolute?).to eq(true)
    end
  end

  describe '#write_summary' do
    let(:writer) {
      StringIO.new
    }
    let(:formatter) {
      Guard::RSpec::Formatter.new(StringIO.new).tap do |formatter|
        formatter.stub(:_write) do |&block|
          block.call writer
        end
      end
    }
    let(:result) {
      writer.rewind
      writer.read
    }

    context 'without stubbed IO' do
      let(:formatter) {
        Guard::RSpec::Formatter.new(StringIO.new)
      }

      it 'creates temporary file and and writes to it' do
        temporary_file_path = described_class.const_get(:TEMPORARY_FILE_PATH)
        expect(FileUtils).to receive(:mkdir_p).with(File.dirname(temporary_file_path)) {}
        expect(File).to receive(:open).with(temporary_file_path, 'w') { |filename, mode, &block| block.call writer }
        formatter.write_summary(123, 1, 2, 3)
      end
    end

    context 'with failures' do
      let(:spec_filename) {
        'failed_location_spec.rb'
      }
      let(:failed_example) { double(
        execution_result: { status: 'failed' },
        metadata: { location: spec_filename }
      ) }

      it 'writes summary line and failed location in tmp dir' do
        allow(formatter).to receive(:examples) { [failed_example] }
        formatter.write_summary(123, 3, 1, 0)
        expect(result).to match /^3 examples, 1 failures in 123\.0 seconds\n#{spec_filename}\n$/
      end

      it 'writes only uniq filenames out' do
        allow(formatter).to receive(:examples) { [failed_example, failed_example] }
        formatter.write_summary(123, 3, 1, 0)
        expect(result).to match /^3 examples, 1 failures in 123\.0 seconds\n#{spec_filename}\n$/
      end

      context "for rspec 3" do
        let(:notification) {
          Struct.new(:duration, :example_count, :failure_count, :pending_count).new(123, 3, 1, 0)
        }
        before do
          formatter.class.stub(:rspec_3?).and_return(true)
        end

        it 'writes summary line and failed location' do
          allow(formatter).to receive(:examples) { [failed_example] }
          formatter.dump_summary(notification)
          expect(result).to match /^3 examples, 1 failures in 123\.0 seconds\n#{spec_filename}\n$/
        end
      end
    end

    it 'should find the spec file for shared examples' do
      metadata = {
        location: './spec/support/breadcrumbs.rb:75',
        example_group: { location: './spec/requests/breadcrumbs_spec.rb:218' }
      }

      expect(described_class.extract_spec_location(metadata)).to start_with './spec/requests/breadcrumbs_spec.rb'
    end

    # Skip location because of rspec issue https://github.com/rspec/rspec-core/issues/1243
    it 'should return only the spec file without line number for shared examples' do
      metadata = {
        location: './spec/support/breadcrumbs.rb:75',
        example_group: { location: './spec/requests/breadcrumbs_spec.rb:218' }
      }

      expect(described_class.extract_spec_location(metadata)).to eq './spec/requests/breadcrumbs_spec.rb'
    end

    it 'should return location of the root spec when a shared examples has no location' do
      metadata = {
        location: './spec/support/breadcrumbs.rb:75',
        example_group: {}
      }

      expect(Guard::UI).to receive(:warning).with("no spec file found for #{metadata[:location]}") {}
      expect(described_class.extract_spec_location(metadata)).to eq metadata[:location]
    end

    context 'with only success' do
      it 'notifies success' do
        formatter.write_summary(123, 3, 0, 0)
        expect(result).to match /^3 examples, 0 failures in 123\.0 seconds\n$/
      end
    end

    context 'with pending' do
      it "notifies pending too" do
        formatter.write_summary(123, 3, 0, 1)
        expect(result).to match /^3 examples, 0 failures \(1 pending\) in 123\.0 seconds\n$/
      end
    end
  end
end
