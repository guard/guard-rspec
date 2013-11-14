require 'spec_helper'
require 'lib/guard/rspec/inspectors/shared_examples'

klass = Guard::RSpec::Inspectors::FocusedInspector

describe klass do
  include_examples 'inspector', klass

  let(:other_paths) { [
    'spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb',
    'spec/lib/guard/rspec/runner_spec.rb'
  ] }
  let(:other_failed_paths) { %w[spec/lib/guard/rspec/deprecator_spec.rb] }

  it 'remembers failed paths and returns them until they all pass' do
    expect(inspector.paths(paths)).to match_array(paths)
    inspector.failed(failed_paths)

    # Return failed_paths until they pass
    3.times do
      expect(inspector.paths(other_paths)).to match_array(failed_paths)
      inspector.failed(other_failed_paths)

      expect(inspector.paths(paths)).to match_array(failed_paths)
      inspector.failed(other_failed_paths)

      expect(inspector.paths([])).to match_array(failed_paths)
      inspector.failed(failed_paths)
    end

    # Now all pass
    expect(inspector.paths(paths)).to match_array(failed_paths)
    inspector.failed([])

    # And some fails again
    expect(inspector.paths(other_paths)).to match_array(other_paths)
    inspector.failed(other_failed_paths)

    # Return other_failed_paths until they pass
    3.times do
      expect(inspector.paths(other_paths)).to match_array(other_failed_paths)
      inspector.failed(other_failed_paths)

      expect(inspector.paths(paths)).to match_array(other_failed_paths)
      inspector.failed(other_failed_paths)

      expect(inspector.paths([])).to match_array(other_failed_paths)
      inspector.failed(failed_paths)
    end

    # Now all pass
    expect(inspector.paths(paths)).to match_array(other_failed_paths)
    inspector.failed([])

    expect(inspector.paths(paths)).to match_array(paths)
    inspector.failed([])

    expect(inspector.paths(other_paths)).to match_array(other_paths)
    inspector.failed([])

    expect(inspector.paths([])).to eq([])
  end

  describe '#reload' do
    it 'force to forget about focused paths' do
      expect(inspector.paths(paths)).to match_array(paths)
      inspector.failed(failed_paths)

      inspector.reload
      expect(inspector.paths(other_paths)).to match_array(other_paths)
    end
  end
end
