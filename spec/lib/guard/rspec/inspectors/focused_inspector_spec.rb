require 'spec_helper'
require 'lib/guard/rspec/inspectors/shared_examples'

klass = Guard::RSpec::Inspectors::FocusedInspector

describe klass do
  include_examples 'inspector', klass

  # Use real paths because BaseInspector#_clean will be used to clean them
  let(:other_paths) { [
    'spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb',
    'spec/lib/guard/rspec/runner_spec.rb'
  ] }
  let(:other_failed_locations) { %w[./spec/lib/guard/rspec/deprecator_spec.rb:446] }

  it 'remembers failed paths and returns them until they all pass' do
    expect(inspector.paths(paths)).to match_array(paths)
    inspector.failed(failed_locations)

    # Return failed_locations until they pass
    3.times do
      expect(inspector.paths(other_paths)).to match_array(failed_locations)
      inspector.failed(other_failed_locations)

      expect(inspector.paths(paths)).to match_array(failed_locations)
      inspector.failed(other_failed_locations)

      expect(inspector.paths([])).to match_array(failed_locations)
      inspector.failed(failed_locations)
    end

    # Now all pass
    expect(inspector.paths(paths)).to match_array(failed_locations)
    inspector.failed([])

    # And some fails again
    expect(inspector.paths(other_paths)).to match_array(other_paths)
    inspector.failed(other_failed_locations)

    # Return other_failed_locations until they pass
    3.times do
      expect(inspector.paths(other_paths)).to match_array(other_failed_locations)
      inspector.failed(other_failed_locations)

      expect(inspector.paths(paths)).to match_array(other_failed_locations)
      inspector.failed(other_failed_locations)

      expect(inspector.paths([])).to match_array(other_failed_locations)
      inspector.failed(failed_locations)
    end

    # Now all pass
    expect(inspector.paths(paths)).to match_array(other_failed_locations)
    inspector.failed([])

    expect(inspector.paths(paths)).to match_array(paths)
    inspector.failed([])

    expect(inspector.paths(other_paths)).to match_array(other_paths)
    inspector.failed([])

    expect(inspector.paths([])).to eq([])
  end

  describe '#reload' do
    it 'force to forget about focused locations' do
      expect(inspector.paths(paths)).to match_array(paths)
      inspector.failed(failed_locations)

      inspector.reload
      expect(inspector.paths(other_paths)).to match_array(other_paths)
    end
  end
end
