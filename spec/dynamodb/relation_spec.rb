# frozen_string_literal: true

require "spec_helper"
require "test_classes/dynamodb_stub"

# Dont need to tag with, dynamodb: true since we are stubbing
RSpec.describe Dynamodb::Relation do
  let(:dynamo_stub) { DynamodbStub }
  let(:subject) { Dynamodb::Relation.new(dynamo_stub) }

  describe "Dynamodb::Relation constants" do
    let(:operation_map) do
      {
        eq:           '=',
        gt:           '>',
        gte:          '>=',
        lt:           '<',
        lte:          '<=',
        begins_with:  'begins_with',
        between:      'BETWEEN'
      }
    end

    let(:query_methods) do
      [
        :index_name, :consistent_read, :scan_index_forward,
        :key_condition_expression, :filter_expression, :expression_attribute_names,
        :expression_attribute_values, :projection_expression, :exclusive_start_key
      ]
    end

    let(:query_instance_vars) {  [:limit] }

    it { expect(Dynamodb::Relation::OPERATOR_MAP).to eq(operation_map) }
    it { expect(Dynamodb::Relation::QUERY_METHODS).to eq(query_methods) }
    it { expect(Dynamodb::Relation::QUERY_INSTANCE_VARS).to eq(query_instance_vars) }
  end

  describe ".initialize(source)" do
    it { expect(subject.source).to eq(dynamo_stub) }
    it { expect(subject.attribute_expressors).to eq({}) }
    it { expect(subject.consistent_read).to eq(false) }
    it { expect(subject.scan_index_forward).to eq(true) }
  end

  describe ".where(args)" do
    context "when when testing index_name" do
      it "calls the setter method then builds expressions and returns self" do
        expect(subject).to receive(:index_name=).with(:name_of_index).and_call_original
        expect(subject).to receive(:build_expressions).and_call_original

        subject.where(index_name: :name_of_index)

        expect(subject.index_name).to eq("name_of_index")
        expect(subject.attribute_expressors).to eq({})
        expect(subject.consistent_read).to eq(false)
        expect(subject.expression_attribute_names).to eq({})
        expect(subject.expression_attribute_values).to eq({})
        expect(subject.filter_expression).to eq("")
        expect(subject.key_condition_expression).to eq("")
        expect(subject.scan_index_forward).to eq(true)
        expect(subject.source).to eq(DynamodbStub)
      end
    end

    context "when args are a hash_key attribute query" do
      it "calls add_attribute_query then builds expressions and returns self" do
        expect(subject).to receive(:add_attribute_query)
          .with(:hash_key, :hash_value).and_call_original
        expect(subject).to receive(:build_expressions).and_call_original

        subject.where(hash_key: :hash_value)

        expect(subject.attribute_expressors).to eq({hash_key: :hash_value})
        expect(subject.consistent_read).to eq(false)
        expect(subject.expression_attribute_names).to eq({"#n1" => "hash_key"})
        expect(subject.expression_attribute_values).to eq({":v1" => :hash_value})
        expect(subject.filter_expression).to eq('')
        expect(subject.key_condition_expression).to eq("#n1 = :v1")
        expect(subject.scan_index_forward).to eq(true)
        expect(subject.source).to eq(DynamodbStub)
      end
    end

    context "when args are a hash_key and range_key attribute query" do
      it "calls add_attribute_query then builds expressions and returns self" do
        expect(subject).to receive(:add_attribute_query)
          .with(:hash_key, :hash_value).and_call_original
        expect(subject).to receive(:add_attribute_query)
          .with(:range_key, { eq: :range_value }).and_call_original
        expect(subject).to receive(:build_expressions).and_call_original

        subject.where(
          {
            hash_key: :hash_value,
            range_key: { eq: :range_value }
          }
        )

        expect(subject.attribute_expressors).to eq(
          {
            hash_key: :hash_value,
            range_key: { eq: :range_value }
          }
        )
        expect(subject.consistent_read).to eq(false)
        expect(subject.expression_attribute_names).to eq(
          {
            "#n1" => "hash_key",
            "#n2" => "range_key"
          }
        )
        expect(subject.expression_attribute_values).to eq(
          {
            ":v1" => :hash_value,
            ":v2" => :range_value,
          }
        )
        expect(subject.filter_expression).to eq('')
        expect(subject.key_condition_expression).to eq(
          "#n1 = :v1 AND #n2 = :v2"
        )
        expect(subject.scan_index_forward).to eq(true)
        expect(subject.source).to eq(DynamodbStub)
      end
    end

    context "when args are a hash_key and filter attribute query" do
      it "calls add_attribute_query then builds expressions and returns self" do
        expect(subject).to receive(:add_attribute_query)
          .with(:hash_key, :hash_value).and_call_original
        expect(subject).to receive(:add_attribute_query)
          .with(:filter_key, { eq: :filter_value }).and_call_original
        expect(subject).to receive(:build_expressions).and_call_original

        subject.where(
          {
            hash_key: :hash_value,
            filter_key: { eq: :filter_value }
          }
        )

        expect(subject.attribute_expressors).to eq(
          {
            hash_key: :hash_value,
            filter_key: { eq: :filter_value }
          }
        )
        expect(subject.consistent_read).to eq(false)
        expect(subject.expression_attribute_names).to eq(
          {
            "#n1" => "hash_key",
            "#n2" => "filter_key"
          }
        )
        expect(subject.expression_attribute_values).to eq(
          {
            ":v1" => :hash_value,
            ":v2" => :filter_value,
          }
        )
        expect(subject.filter_expression).to eq("#n2 = :v2")
        expect(subject.key_condition_expression).to eq("#n1 = :v1")
        expect(subject.scan_index_forward).to eq(true)
        expect(subject.source).to eq(DynamodbStub)
      end
    end
  end

  describe ".limit(int)" do
    it "sets limit instance var then builds expressions and returns self" do
      expect(subject).to receive(:build_expressions).and_call_original

      subject.limit(100)

      expect(subject.instance_variable_get("@_limit")).to eq(100)
    end
  end

  describe ".select(*args)" do
    it "sets projection_expression with args then builds expressions and returns self" do
      expect(subject).to receive(:build_expressions).and_call_original

      subject.select([:hash_key, :range_key])

      expect(subject.instance_variable_get("@projection_expression")).to eq(
        [:hash_key, :range_key]
      )
    end
  end

  describe ".all" do
    it "calls _query on source" do
      expect(subject).to receive(:build_query) { {} }
      expect(subject.source).to receive(:_query).with({})

      subject.all
    end
  end

  describe ".to_query" do
    it "calls build_query" do
      expect(subject).to receive(:build_query) { {} }

      subject.to_query
    end
  end

  describe ".query(args = {})" do
    it 'calls _query on source with args' do
      expect(subject.source).to receive(:_query).with({foo: :bar})

      subject.query(foo: :bar)
    end
  end

  describe ".key_condition_expression" do
    it "joins key_condition_expression with AND" do
      subject.instance_variable_set("@key_condition_expression", [:foo, :bar])

      expect(subject.key_condition_expression).to eq("foo AND bar")
    end
  end

  describe ".filter_expression" do
    it "joins filter_expression with AND" do
      subject.instance_variable_set("@filter_expression", [:foo, :bar])

      expect(subject.filter_expression).to eq("foo AND bar")
    end
  end

  describe ".projection_expression" do
    it "returns nil when projection_expression is nil" do
      subject.instance_variable_set("@projection_expression", nil)

      expect(subject.projection_expression).to eq(nil)
    end

    it "joins projection_expression with comma" do
      subject.instance_variable_set("@projection_expression", [:foo, :bar])

      expect(subject.projection_expression).to eq("foo, bar")
    end
  end

  describe ".exclusive_start_key" do
    it "returns nil when @offset_key is nil" do
      subject.instance_variable_set("@offset_key", nil)

      expect(subject.exclusive_start_key).to eq(nil)
    end

    it "returns exclusive_start_key" do
      subject.instance_variable_set("@offset_key", { foo: :bar })

      expect(subject.exclusive_start_key).to eq({ foo: :bar })
    end
  end
end
