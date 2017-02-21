require 'spec_helper'

describe Tainbox do

  it 'works' do

    person = Class.new do
      include Tainbox
      attribute :name, default: 'Oliver'
      attribute :age, Integer

      def name
        super.strip
      end
    end

    person = person.new(name: ' John ', 'age' => '24')
    expect(person.name).to eq('John')
    expect(person.age).to eq(24)
    expect(person.attribute_provided?(:name)).to be_truthy
    expect(person.attribute_provided?(:age)).to be_truthy

    person.attributes = {}
    expect(person.name).to eq('Oliver')
    expect(person.age).to be_nil
    expect(person.attribute_provided?(:name)).to be_truthy
    expect(person.attribute_provided?(:age)).to be_falsey

    expect(person.attributes).to eq(name: 'Oliver', age: nil)

    person.age = 10
    expect(person.age).to eq(10)
    expect(person.attribute_provided?(:age)).to be_truthy

    expect(person.as_json).to eq('name' => 'Oliver', 'age' => 10)
    expect(person.as_json(only: :name)).to eq('name' => 'Oliver')
    expect(person.as_json(except: :name)).to eq('age' => 10)
  end

  it 'accepts objects which respond to #to_h as attributes' do

    person = Class.new do
      include Tainbox
      attribute :name, default: 'Oliver'
      attribute :age, Integer

      def name
        super.strip
      end
    end

    expect(person.new(name: 'John').name).to eq('John')
    expect(person.new([[:name, 'John']]).name).to eq('John')
    expect(person.new(nil).name).to eq('Oliver')

    exception = 'Attributes can only be assigned via objects which respond to #to_h'
    expect { person.new('Hello world') }.to raise_exception(ArgumentError, exception)
  end

  describe 'string converter options' do

    describe 'no options' do
      let(:person) do
        Class.new do
          include Tainbox
          attribute :name, String
        end
      end

      specify 'no value given' do
        expect(person.new.name).to be_nil
      end

      specify 'nil given' do
        expect(person.new(name: nil).name).to eq('')
      end

      specify 'string given' do
        expect(person.new(name: ' Hello ').name).to eq(' Hello ')
      end
    end

    describe 'strip' do
      let(:person) do
        Class.new do
          include Tainbox
          attribute :name, String, strip: true
        end
      end

      specify 'no value given' do
        expect(person.new.name).to be_nil
      end

      specify 'nil given' do
        expect(person.new(name: nil).name).to eq('')
      end

      specify 'string given' do
        expect(person.new(name: ' Hello ').name).to eq('Hello')
      end
    end

    describe 'downcase' do
      let(:person) do
        Class.new do
          include Tainbox
          attribute :name, String, downcase: true
        end
      end

      specify 'no value given' do
        expect(person.new.name).to be_nil
      end

      specify 'nil given' do
        expect(person.new(name: nil).name).to eq('')
      end

      specify 'string given' do
        expect(person.new(name: ' Hello ').name).to eq(' hello ')
      end
    end

    describe 'strip and downcase' do
      let(:person) do
        Class.new do
          include Tainbox
          attribute :name, String, strip: true, downcase: true
        end
      end

      specify 'no value given' do
        expect(person.new.name).to be_nil
      end

      specify 'nil given' do
        expect(person.new(name: nil).name).to eq('')
      end

      specify 'string given' do
        expect(person.new(name: ' Hello ').name).to eq('hello')
      end
    end
  end

  describe '#to_json' do
    subject { model_class.new(foo: :bar) }

    let(:model_class) do
      Class.new { include Tainbox }
    end

    context 'default appearence' do
      before { model_class.send(:attribute, :foo) }
      its(:to_json) { is_expected.to eq <<-JSON.strip }
        {"foo":"bar"}
      JSON
    end

    context 'force_super used for as_json' do
      before { model_class.class_eval <<-RUBY }
        def to_hash
          { foo: :bar }
        end

        def as_json(**options)
          super(**options, force_super: true)
        end
      RUBY

      its(:to_json) { is_expected.to eq <<-JSON.strip }
        {"foo":"bar"}
      JSON
    end
  end
end
