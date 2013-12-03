require 'spec_helper'

describe Guard::RSpec::Inspectors::BaseInspector do
  let(:options) { { custom: 'value', spec_paths: %w[myspec] } }
  let(:inspector) { Guard::RSpec::Inspectors::BaseInspector.new(options) }
  let(:paths) { %w[spec/foo_spec.rb spec/bar_spec.rb] }
  let(:abstract_error) { 'Must be implemented in subclass' }

  describe '.initialize' do
    it 'sets options and spec_paths' do
      expect(inspector.options).to include(:custom, :spec_paths)
      expect(inspector.options[:custom]).to eq('value')
      expect(inspector.spec_paths).to eq(%w[myspec])
    end
  end

  describe '#paths' do
    it 'should not be emplemented here' do
      expect { inspector.paths(paths) }.to raise_error(abstract_error)
    end
  end

  describe '#failed' do
    it 'should not be emplemented here' do
      expect { inspector.failed(paths) }.to raise_error(abstract_error)
    end
  end

  describe '#reload' do
    it 'should not be emplemented here' do
      expect { inspector.reload }.to raise_error(abstract_error)
    end
  end
end
