# frozen_string_literal: true

require "spec_helper"
require "test_classes/dynamodb_stub"

RSpec.describe Dynamodb::AttributeAssignment do
  let(:dynamo_stub) { DynamodbStub }
  let(:dynamo_instance) { dynamo_stub.new({}) }
  let(:local_indexes) do
    [
      {
        type: :local,
        index_name: "stub_local_index",
        key_schema: [
          {
            attribute_name: "hash_key",
            key_type: "HASH"
          },
          {
            attribute_name: "local_index_key",
            key_type: "RANGE"
          }
        ],
        projection: {
          projection_type: "ALL"
        }
      },
      {
        type: :local,
        index_name: "another_local_index",
        key_schema: [
          {
            attribute_name: "hash_key",
            key_type: "HASH"
          },
          {
            attribute_name: "another_index_key",
            key_type: "RANGE"
          }
        ],
        projection: {
          projection_type: "ALL"
        }
      }
    ]
  end
  let(:global_indexes) do
    [
      {
        type: :global,
        index_name: "stub_global_index",
        key_schema: [
          {
            attribute_name: "global_hash_key",
            key_type: "HASH"
          },
          {
            attribute_name: "global_range_key",
            key_type: "RANGE"
          }
        ],
        projection: {
          projection_type: "ALL"
        }
      }
    ]
  end

  describe "Dynamodb::AttributeAssignment constants" do
    let(:attribute_types) do
      {
        string: "S",
        number: "N",
        binary: "B"
      }
    end
    let(:key_types) do
      {
        hash: "HASH",
        range: "RANGE"
      }
    end
    let(:projection_types) do
      {
        all: "ALL",
        keys: "KEYS_ONLY",
        include: "INCLUDE"
      }
    end

    it { expect(Dynamodb::AttributeAssignment::ATTRIBUTE_TYPES).to eq(attribute_types) }
    it { expect(Dynamodb::AttributeAssignment::KEY_TYPES).to eq(key_types) }
    it { expect(Dynamodb::AttributeAssignment::PROJECTION_TYPES).to eq(projection_types) }
  end

  describe ".table_name(_table_name = nil)" do
    context "not passing the table_name with the method" do
      it "should access table_name as class accessor" do
        expect(dynamo_stub.table_name).to eq("dynamodb_stubs")
      end
    end

    context "passing the table_name with the method" do
      let(:table_name) { :some_table }
      it "should set table_name class accessor and return it" do
        dynamo_stub.table_name(table_name)

        expect(dynamo_stub.table_name).to eq(table_name.to_s)
      end
    end

    it "should access table_name as instance accessor" do
      expect(dynamo_instance.table_name).to eq("dynamodb_stubs")
    end
  end

  describe ".hash_key" do
    it "should access hash_key as class accessor" do
      expect(dynamo_stub.hash_key).to eq("hash_key")
    end

    it "should access hash_key as instance accessor" do
      expect(dynamo_instance.hash_key).to eq("hash_key")
    end
  end

  describe ".range_key" do
    it "should access range_key as class accessor" do
      expect(dynamo_stub.range_key).to eq("range_key")
    end

    it "should access range_key as instance accessor" do
      expect(dynamo_instance.range_key).to eq("range_key")
    end
  end

  describe ".client" do
    it "should access client as instance method" do
      expect(dynamo_instance.client).to eq(dynamo_stub.client)
    end
  end

  describe ".indexes" do
    let(:expected_result) { local_indexes + global_indexes }

    it "should access indexes as class accessor" do
      expect(dynamo_stub.indexes).to eq(expected_result)
    end

    it "should access indexes as instance method" do
      expect(dynamo_instance.indexes).to eq(dynamo_stub.indexes)
    end
  end

  describe ".local_indexes" do
    let(:expected_result) do
      local_indexes.map { |h| h.select { |k| k != :type }}
    end

    it "should access indexes as class accessor" do
      expect(dynamo_stub.local_indexes).to eq(expected_result)
    end

    it "should access local_indexes as instance method" do
      expect(dynamo_instance.local_indexes).to eq(dynamo_stub.local_indexes)
    end
  end

  describe ".global_indexes" do
    let(:expected_result) do
      global_indexes.map { |h| h.select { |k| k != :type }}
    end

    it "should access indexes as class accessor" do
      expect(dynamo_stub.global_indexes).to eq(expected_result)
    end

    it "should access global_indexes as instance method" do
      expect(dynamo_instance.global_indexes).to eq(dynamo_stub.global_indexes)
    end
  end

  describe ".attribute_definitions" do
    it "should access hash_key as class accessor" do
      expect(dynamo_stub.attribute_definitions).to(
        eq([
          { attribute_name: "hash_key", attribute_type: "N" },
          { attribute_name: "range_key", attribute_type: "S" },
          { attribute_name: "local_index_key", attribute_type: "S" },
          { attribute_name: "another_index_key", attribute_type: "S" },
          { attribute_name: "global_hash_key", attribute_type: "S" },
          { attribute_name: "global_range_key", attribute_type: "S" }
        ])
      )
    end
  end

  describe ".key(attr_name, attr_type, options)" do
    let(:attr_name) { :attr_name }
    let(:attr_type) { :number }
    let(:options) { { key: :hash } }

    it "should call expected methods" do
      expect(dynamo_stub).to(
        receive(:instance_variable_set).with(
          "@#{options[:key]}_key", attr_name.to_s
        )
      )

      expect(dynamo_stub).to(
        receive(:define_attribute).with(
          { name: attr_name, type: attr_type }
        )
      )

      expect(dynamo_stub).to(
        receive(:define_key_schema).with(attr_name, options[:key])
      )

      dynamo_stub.key(attr_name, attr_type, options)
    end
  end

  describe ".local_index(options)" do
    let(:options) do
      {
        key: {
          name: :foo,
          type: :bar
        }
      }
    end

    it "should call expected methods" do
      expect(dynamo_stub).to receive(:define_local_index).with(options)

      expect(dynamo_stub).to(
        receive(:define_attribute).with(
          { name: options[:key][:name], type: options[:key][:type] }
        )
      )

      dynamo_stub.local_index(options)
    end
  end

  describe ".global_index(options)" do
    let(:options) do
      {
        keys: {
          hash: {
            name: :foo,
            type: :bar
          },
          range: {
            name: :foo,
            type: :bar
          }
        }
      }
    end

    it "should call expected methods" do
      expect(dynamo_stub).to receive(:define_global_index).with(options)

      expect(dynamo_stub).to(
        receive(:define_attribute).with(
          {
            name: options[:keys][:hash][:name],
            type: options[:keys][:hash][:type]
          }
        )
      )

      expect(dynamo_stub).to(
        receive(:define_attribute).with(
          {
            name: options[:keys][:range][:name],
            type: options[:keys][:range][:type]
          }
        )
      )

      dynamo_stub.global_index(options)
    end
  end

  describe ".time_to_live(&block)" do
    it "should define schedule_time_to_live to an instance of the class" do
      dynamo_stub.time_to_live { "some block of code" }
      expect(dynamo_instance.schedule_time_to_live).to eq("some block of code")
    end
  end
end
