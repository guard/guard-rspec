require 'spec_helper.rb'

require 'guard/rspec/formatter'

describe Guard::RSpec::Formatter do
  let(:writer){
    StringIO.new
  }
  let(:formatter) {
    Guard::RSpec::Formatter.new(StringIO.new).tap{|formatter|
      formatter.stub(:write) do |&block|
        block.call writer
      end
    }
  }

  describe '#dump_summary' do

    let(:result){
      writer.rewind
      writer.read
    }


    context 'with failures' do
      let(:spec_filename){
        'failed_location_spec.rb'
      }

      let(:failed_example) { double(
        execution_result: { status: 'failed' },
        metadata: { location: spec_filename }
      ) }

      it 'writes summary line and failed location in tmp dir' do
        allow(formatter).to receive(:examples) { [failed_example] }
        formatter.dump_summary(123, 3, 1, 0)
        expect(result).to match /^3 examples, 1 failures in 123\.0 seconds\n#{spec_filename}\n$/
      end

      it 'writes only uniq filenames out' do
        allow(formatter).to receive(:examples) { [failed_example, failed_example] }
        formatter.dump_summary(123, 3, 1, 0)
        expect(result).to match /^3 examples, 1 failures in 123\.0 seconds\n#{spec_filename}\n$/
      end

    end

    it "should find the spec file for shared examples" do
      metadata = {:location => './spec/support/breadcrumbs.rb:75',
                  :example_group => {:location => './spec/requests/breadcrumbs_spec.rb:218'}
                 }

      expect(described_class.extract_spec_location(metadata)).to start_with './spec/requests/breadcrumbs_spec.rb'
    end

    it "should return only the spec file without line number for shared examples" do
      metadata = {:location => './spec/support/breadcrumbs.rb:75',
                  :example_group => {:location => './spec/requests/breadcrumbs_spec.rb:218'}
      }

      expect(described_class.extract_spec_location(metadata)).to eq './spec/requests/breadcrumbs_spec.rb'
    end

    it "should return location of the root spec when a shared examples has no location" do
      metadata = {:location => './spec/support/breadcrumbs.rb:75',
                  :example_group => {}
      }

      expect(described_class.extract_spec_location(metadata)).to eq metadata[:location]
    end

    context 'with only success' do
      it 'notifies success' do
        formatter.dump_summary(123, 3, 0, 0)
        expect(result).to match /^3 examples, 0 failures in 123\.0 seconds\n$/
      end
    end

    context 'with pending' do
      it "notifies pending too" do
        formatter.dump_summary(123, 3, 0, 1)
        expect(result).to match /^3 examples, 0 failures \(1 pending\) in 123\.0 seconds\n$/
      end
    end
  end

end
