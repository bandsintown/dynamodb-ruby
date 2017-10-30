# frozen_string_literal: true

require "spec_helper"
require "test_classes/dynamodb_stub"

# NOTE: Need to handle the hash_key thats being called but not set
RSpec.describe Dynamodb::Base do
  let(:dynamo_stub) { DynamodbStub }
  let(:dynamo_instance) { dynamo_stub.new(data) }
  let(:data) do
    {
      hash_key: 123,
      range_key: 345,
      foo: true
    }
  end
  let(:result_data) do
    {
      hash_key: 123,
      range_key: 345,
      foo: true
    }.with_indifferent_access
  end

  describe ".initialize(data = {}, new_record = true)" do
    it "should set @data" do
      expect(dynamo_instance.data).to eq(result_data)
    end

    it "should set @new_record to true" do
      expect(dynamo_instance.new_record?).to eq(true)
    end

    it "should set @errors to []" do
      expect(dynamo_instance.errors).to eq([])
    end
  end

  describe ".data=(val)" do
    it "should set dynamo_instance.data=" do
      expect(dynamo_instance.data=data).to eq(result_data.symbolize_keys)
    end
  end

  describe ".data" do
    it "should return correct data" do
      expect(dynamo_instance.data).to eq(result_data)
    end

    context "when hash_key is an BigInt" do
      let(:data) do
        {
          hash_key: 123.00,
          range_key: 345,
          foo: true
        }
      end

      let(:result_data) do
        {
          hash_key: 123,
          range_key: 345,
          foo: true
        }.with_indifferent_access
      end

      it "should set correct data and return hash_key as an int" do
        expect(dynamo_instance.data).to eq(result_data)
      end
    end
  end

  describe ".new_record?" do
    context "when object is a new_record" do
      it { expect(dynamo_instance.new_record?).to eq(true) }
    end

    context "when object is not a new_record" do
      let(:dynamo_instance) { dynamo_stub.new(data, false) }

      it { expect(dynamo_instance.new_record?).to eq(false) }
    end
  end

  describe ".valid?" do
    context "when data is valid" do
      it { expect(dynamo_instance.valid?).to eq(true) }
    end

    context "when data is not valid" do
      # TODO: need to validate data is a hash earlier
      # let(:data) { "a string" } Throws errors
      let(:data) { {} }

      it { expect(dynamo_instance.valid?).to eq(false) }

      it "returns an error message" do
        dynamo_instance.valid?
        expect(dynamo_instance.errors).to eq(["Incorrect format of data"])
      end
    end

    context "when hash_key is not valid" do
      let(:data) do
        {
          range_key: 345,
          foo: true
        }
      end

      it { expect(dynamo_instance.valid?).to eq(false) }

      it "returns an error message" do
        dynamo_instance.valid?
        expect(dynamo_instance.errors).to eq(["Incorrect format of data"])
      end
    end

    context "when range_key is not valid" do
      let(:data) do
        {
          hash_key: 123,
          foo: true
        }
      end

      it { expect(dynamo_instance.valid?).to eq(false) }

      it "returns an error message" do
        dynamo_instance.valid?
        expect(dynamo_instance.errors).to eq(["Incorrect format of data"])
      end
    end
  end

  describe ".handle_error(e)" do
    let(:e) { OpenStruct.new(message: "Error Message") }

    it "adds error to errors attribute" do
      dynamo_instance.handle_error(e)

      expect(dynamo_instance.errors).to eq([e.message])
    end
  end

  describe ".add_error(e)" do
    let(:e) { "Error Message" }

    it "adds error to errors attribute" do

      dynamo_instance.add_error(e)

      expect(dynamo_instance.errors).to eq([e])
    end
  end

  describe "generate_timestamps" do
    let(:timestamps) do
      {
        updated_at: Time.now.utc.iso8601,
        created_at: Time.now.utc.iso8601
      }
    end

    it "it generate timestamps for object" do
      data = dynamo_instance.data

      dynamo_instance.generate_timestamps

      expect(dynamo_instance.data).to eq(data.merge(timestamps))
    end

    context "when there is a time to live for item" do
      it "calls schedule_time_to_live" do
        dynamo_instance.class.time_to_live { "some block of code" }
        expect(dynamo_instance).to receive(:schedule_time_to_live)

        dynamo_instance.generate_timestamps
      end
    end
  end
end
