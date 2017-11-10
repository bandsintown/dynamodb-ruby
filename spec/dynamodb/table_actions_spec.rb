# frozen_string_literal: true

require "spec_helper"
require "test_classes/dynamodb_stub"

# Need to handle the hash_key thats being called but not set
RSpec.describe Dynamodb::TableActions do
  let(:dynamo_stub) { DynamodbStub }
  let(:table_name) { "table_name" }
  let(:key) { "key" }
  let(:options) { { foo: :bar } }
  let(:item) { { item: :some_item } }

  describe ".get_item(_table_name, _key, options = {})" do
    it "calls get_item on client and returns the item" do
      expect(dynamo_stub.client).to receive(:get_item).with(
        {
          table_name: table_name,
          key: key
        }.merge(options)
      ) { item }

      expect(dynamo_stub).to receive(:item_to_object).with(item[:item])

      dynamo_stub.get_item(table_name, key, options)
    end
  end

  describe ".put_item(_table_name, _item, options = {})" do
    it "calls put_item on client" do
      expect(dynamo_stub.client).to receive(:put_item).with(
        {
          table_name: table_name,
          item: item
        }.merge(options)
      )

      dynamo_stub.put_item(table_name, item, options)
    end
  end

  describe ".delete_item(_table_name, _key, options = {})" do
    it "calls delete_item on client" do
      expect(dynamo_stub.client).to receive(:delete_item).with(
        {
          table_name: table_name,
          key: key
        }.merge(options)
      )

      dynamo_stub.delete_item(table_name, key, options)
    end
  end

  describe "._query(opts)" do
    let(:items_result) { OpenStruct.new(items: [{ foo: :bar }]) }

    it "calls query on client" do
      expect(dynamo_stub.client).to receive(:query).with(options) { items_result }

      dynamo_stub._query(options)
    end
  end

  describe ".describe_table(_table_name)" do
    it "should call describe_table on client with table_name" do
      expect(dynamo_stub.client).to(
        receive(:describe_table).with(table_name: "table_name")
      )

      dynamo_stub.describe_table("table_name")
    end
  end

  describe ".list_tables" do
    let(:tables) { OpenStruct.new(table_names: true) }

    it "should call list_tables on client" do
      expect(dynamo_stub.client).to receive(:list_tables) { tables }
      expect(tables).to receive(:table_names)

      dynamo_stub.list_tables
    end
  end

  describe ".delete_table(_table_name)" do
    before do
      Dynamodb.configure { |config| config.can_delete_tables = true }
    end

    it "should call delete_table on client with table_name" do
      expect(dynamo_stub.client).to receive(:delete_table)
        .with(table_name: "table_name")

      dynamo_stub.delete_table("table_name")
    end

    context "when config can delete tables is false" do
      before do
        Dynamodb.configure { |config| config.can_delete_tables = false }
      end

      it "should not call delete_table and raise an exception" do
        expect { dynamo_stub.delete_table("table_name") }
          .to raise_error("Can not delete tables")
      end
    end
  end

  describe ".create_table(_table_name, options)" do
    before do
      Dynamodb.configure { |config| config.can_create_tables = true }
    end

    it "should call create_table on client with table_name" do
      expect(dynamo_stub.resource).to receive(:create_table)
        .with({
          table_name: "table_name",
          provisioned_throughput: {
            read_capacity_units: 5,
            write_capacity_units: 5,
          },
          foo: :bar
        })

      dynamo_stub.create_table("table_name", { foo: :bar })
    end

    context "when config can create tables is false" do
      before do
        Dynamodb.configure { |config| config.can_create_tables = false }
      end

      it "should not call create_table and raise an exception" do
        expect { dynamo_stub.create_table("table_name", {}) }
          .to raise_error("Can not create tables")
      end
    end
  end
end
