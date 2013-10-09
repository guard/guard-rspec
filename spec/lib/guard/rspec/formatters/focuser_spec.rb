require 'spec_helper.rb'

require 'guard/rspec/formatters/focuser'

describe Guard::RSpec::Formatters::Focuser do
  let(:formatter) { Guard::RSpec::Formatters::Focuser.new(StringIO.new) }

  describe "#dump_summary" do
    context "with failures" do
      let(:example) { double(
        execution_result: { status: 'failed' },
        metadata: { location: 'failed_location' }
      ) }
      after { File.delete('./tmp/rspec_guard_result') }

      it "writes failed location in tmp dir" do
        formatter.stub(:examples) { [example] }
        formatter.dump_summary(123, 3, 1, 0)
        result = File.open('./tmp/rspec_guard_result').read
        expect(result).to eq "failed_location\n"
      end
    end
  end

end
