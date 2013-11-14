require 'spec_helper'

describe Guard::RSpec::Inspectors::Factory do
  let(:factory) { Guard::RSpec::Inspectors::Factory }
  let(:options) { {} }

  it 'can not be instantiated' do
    expect { factory.new(options) }.to raise_error(NoMethodError)
  end

  context 'with :focus_on_failed and :custom options' do
    let(:options) { { focus_on_failed: true, custom: 'value' } }

    it 'creates FocusedInspector instance with custom options' do
      inspector = factory.create(options)
      expect(inspector).to be_an_instance_of(Guard::RSpec::Inspectors::FocusedInspector)
      expect(inspector.options[:focus_on_failed]).to be_true
      expect(inspector.options[:custom]).to eq('value')
    end
  end

  context 'without :focus_on_failed option' do
    let(:common_options) { { focus_on_failed: false } }

    context 'with :keep_failed and :custom options' do
      let(:options) { common_options.merge(keep_failed: true, custom: 'value') }

      it 'creates KeepingInspector instance with custom options' do
        inspector = factory.create(options)
        expect(inspector).to be_an_instance_of(Guard::RSpec::Inspectors::KeepingInspector)
        expect(inspector.options[:focus_on_failed]).to be_false
        expect(inspector.options[:keep_failed]).to be_true
        expect(inspector.options[:custom]).to eq('value')
      end
    end

    context 'without :keep_failed and with :custom options' do
      let(:options) { common_options.merge(keep_failed: false, custom: 'value') }

      it 'creates SimpleInspector instance with custom options' do
        inspector = factory.create(options)
        expect(inspector).to be_an_instance_of(Guard::RSpec::Inspectors::SimpleInspector)
        expect(inspector.options[:focus_on_failed]).to be_false
        expect(inspector.options[:keep_failed]).to be_false
        expect(inspector.options[:custom]).to eq('value')
      end
    end
  end
end
