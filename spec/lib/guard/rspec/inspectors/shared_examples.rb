require 'spec_helper'

shared_examples 'inspector' do |klass|
  let(:spec_paths) { %w[spec myspec] }
  let(:options) { { custom: 'value', spec_paths: spec_paths } }
  let(:inspector) { klass.new(options) }

  # Use real paths because BaseInspector#_clean will be used to clean them
  let(:paths) { [
    'spec/lib/guard/rspec/inspectors/base_inspector_spec.rb',
    'spec/lib/guard/rspec/runner_spec.rb',
    'spec/lib/guard/rspec/deprecator_spec.rb'
  ] }
  let(:failed_locations) { [
    './spec/lib/guard/rspec/runner_spec.rb:12',
    './spec/lib/guard/rspec/deprecator_spec.rb:55'
  ] }

  describe '.initialize' do
    it 'sets options and spec_paths' do
      expect(inspector.options).to include(:custom, :spec_paths)
      expect(inspector.options[:custom]).to eq('value')
      expect(inspector.spec_paths).to eq(spec_paths)
    end
  end

  describe '#paths' do
    it 'returns paths when called first time' do
      expect(inspector.paths(paths)).to match_array(paths)
    end

    it 'does not return non-spec paths' do
      paths = %w[not_a_spec_path.rb spec/not_exist_spec.rb]
      expect(inspector.paths(paths)).to eq([])
    end

    it 'uniq and compact paths' do
      expect(inspector.paths(paths + paths + [nil, nil, nil])).to match_array(paths)
    end

    # NOTE: I'm not sure that it is totally correct behaviour
    it 'return spec_paths and directories too' do
      paths = %w[myspec lib/guard not_exist_dir]
      expect(inspector.paths(paths)).to match_array(paths - ['not_exist_dir'])
    end
  end

  describe '#failed' do
    it 'is callable' do
      expect { inspector.failed(failed_locations) }.not_to raise_error
    end
  end

  describe '#reload' do
    it 'is callable' do
      expect { inspector.reload }.not_to raise_error
    end
  end
end
