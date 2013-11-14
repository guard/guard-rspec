require 'spec_helper'
require 'lib/guard/rspec/inspectors/shared_examples'

klass = Guard::RSpec::Inspectors::SimpleInspector

describe klass do
  include_examples 'inspector', klass

  let(:other_paths) { [
    'spec/lib/guard/rspec/inspectors/simple_inspector_spec.rb',
    'spec/lib/guard/rspec/runner_spec.rb'
  ] }

  it 'returns paths and do not bothers about failed paths' do
    2.times do
      expect(inspector.paths(paths)).to eq(paths)
      inspector.failed(failed_paths)
      expect(inspector.paths(other_paths)).to eq(other_paths)
      inspector.failed([])
    end
  end
end
