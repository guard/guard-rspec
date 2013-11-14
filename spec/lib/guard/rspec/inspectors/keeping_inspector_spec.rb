require 'spec_helper'
require 'lib/guard/rspec/inspectors/shared_examples'

klass = Guard::RSpec::Inspectors::KeepingInspector

describe klass do
  include_examples 'inspector', klass

  let(:other_paths) { [
    'spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb',
    'spec/lib/guard/rspec/runner_spec.rb'
  ] }

  it 'remembers failed paths and returns them along with new paths' do
    expect(inspector.paths(paths)).to eq(paths)
    inspector.failed(failed_paths)

    expect(inspector.paths(other_paths)).to match_array(other_paths | failed_paths)
    inspector.failed(other_paths)

    expect(inspector.paths([])).to match_array(other_paths)
    inspector.failed([])

    expect(inspector.paths(paths)).to match_array(paths)
    inspector.failed([])

    expect(inspector.paths([])).to eq([])
  end

  describe '#reload' do
    it 'force to forget about failed paths' do
      expect(inspector.paths(paths)).to eq(paths)
      inspector.failed(failed_paths)

      inspector.reload
      expect(inspector.paths(other_paths)).to match_array(other_paths)
    end
  end
end
