require 'spec_helper'
require 'lib/guard/rspec/inspectors/shared_examples'

klass = Guard::RSpec::Inspectors::KeepingInspector

describe klass do
  include_examples 'inspector', klass

  # Use real paths because BaseInspector#_clean will be used to clean them
  let(:other_paths) { [
    'spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb',
    'spec/lib/guard/rspec/runner_spec.rb'
  ] }
  let(:other_failed_locations) { [
    './spec/lib/guard/rspec/runner_spec.rb:12',
    './spec/lib/guard/rspec/runner_spec.rb:100',
    './spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb:12'
  ] }

  it 'remembers failed paths and returns them along with new paths' do
    expect(inspector.paths(paths)).to eq(paths)
    inspector.failed(failed_locations)

    expect(inspector.paths(other_paths)).to match_array(other_paths | failed_locations)
    inspector.failed(other_failed_locations)

    expect(inspector.paths([])).to match_array(other_failed_locations)
    inspector.failed([])

    expect(inspector.paths(paths)).to match_array(paths)
    inspector.failed([])

    expect(inspector.paths([])).to eq([])
  end

  describe '#reload' do
    it 'force to forget about failed locations' do
      expect(inspector.paths(paths)).to eq(paths)
      inspector.failed(failed_locations)

      inspector.reload
      expect(inspector.paths(other_paths)).to match_array(other_paths)
    end
  end
end
