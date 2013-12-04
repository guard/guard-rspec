require 'spec_helper.rb'

require 'guard/rspec/formatter'

describe Guard::RSpec::Formatter do
  let(:formatter) { Guard::RSpec::Formatter.new(StringIO.new) }

  describe '#dump_summary' do
    after { File.delete('./tmp/rspec_guard_result') }

    context 'with failures' do
      let(:failed_example) { double(
        execution_result: { status: 'failed' },
        metadata: { location: 'failed_location' }
      ) }

      it 'writes summary line and failed location in tmp dir' do
        allow(formatter).to receive(:examples) { [failed_example] }
        formatter.dump_summary(123, 3, 1, 0)
        result = File.open('./tmp/rspec_guard_result').read
        expect(result).to match /^3 examples, 1 failures in 123\.0 seconds\nfailed_location\n$/
      end
    end

    context 'with only success' do
      it 'notifies success' do
        formatter.dump_summary(123, 3, 0, 0)
        result = File.open('./tmp/rspec_guard_result').read
        expect(result).to match /^3 examples, 0 failures in 123\.0 seconds\n$/
      end
    end

    context 'with pending' do
      it "notifies pending too" do
        formatter.dump_summary(123, 3, 0, 1)
        result = File.open('./tmp/rspec_guard_result').read
        expect(result).to match /^3 examples, 0 failures \(1 pending\) in 123\.0 seconds\n$/
      end
    end
  end

end
