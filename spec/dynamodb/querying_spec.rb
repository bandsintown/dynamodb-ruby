# frozen_string_literal: true

require "spec_helper"
require "test_classes/dynamodb_stub"

RSpec.describe Dynamodb::Querying do
  let(:dynamo_stub) { DynamodbStub }
  let(:dynamo_instance) { dynamo_stub.new(data) }
  let(:client) { Aws::DynamoDB::Client.new(stub_responses: true) }
  let(:data) do
    {
      hash_key: 123,
      range_key: 345,
      test_key: "123",
      foo: true
    }.merge(timestamps)
  end
  let(:result_data) do
    {
      hash_key: 123,
      range_key: 345,
      test_key: "123",
      foo: true
    }.merge(timestamps).with_indifferent_access
  end
  let(:timestamps) do
    {
      updated_at: Time.now.utc.iso8601,
      created_at: Time.now.utc.iso8601,
      expires_at: (DateTime.now >> 3).to_time.to_i
    }
  end

  # NOTE: Need to reset the Dynamodb::Connection for testing
  before(:each) do
    dynamo_stub.client = client
  end

  describe ".update(attributes = {})" do
    let(:tested_record) { dynamo_stub.find(123) }
    let(:attributes) { { foo: "false" } }

    before do
      dynamo_stub.client.stub_responses(:get_item, { item: result_data })
    end

    context "when attributes are valid" do
      it "should return with no errors" do
        dynamo_stub.client.stub_responses(:put_item, false)

        expect(dynamo_instance.update(attributes)).to eq(true)
        expect(dynamo_instance.errors.empty?).to eq(true)
      end
    end

    context "when data is not valid" do
      before do
        allow(dynamo_instance).to receive(:valid?).and_return(false)
      end

      it "should return with validation errors" do
        expect(dynamo_instance.update(attributes)).to eq(false)
      end
    end

    context "when AWS returns a ServiceError" do
      it "should return with errors" do
        dynamo_stub.client.stub_responses(:put_item, "ServiceError")

        dynamo_instance.update(attributes)

        expect(dynamo_instance.errors).to eq(["stubbed-response-error-message"])
      end
    end
  end

  describe '.save' do
    let(:tested_record) { dynamo_stub.find(123) }

    before do
      dynamo_stub.client.stub_responses(:get_item, { item: result_data })
    end

    context "when data id valid" do
      it "should return with no errors" do
        dynamo_stub.client.stub_responses(:put_item, false)

        expect(dynamo_instance.save).to eq(true)
        expect(dynamo_instance.errors.empty?).to eq(true)
      end
    end

    context "when data is not valid" do
      before do
        allow(dynamo_instance).to receive(:valid?).and_return(false)
      end

      it "should return with validation errors" do
        expect(dynamo_instance.save).to eq(false)
      end
    end

    context "when AWS returns a ServiceError" do
      it "should return with errors" do
        dynamo_stub.client.stub_responses(:put_item, "ServiceError")

        dynamo_instance.save

        expect(dynamo_instance.errors).to eq(["stubbed-response-error-message"])
      end
    end
  end

  describe ".destroy" do
    let(:tested_record) { dynamo_stub.find(123) }

    before do
      dynamo_stub.client.stub_responses(:get_item, { item: result_data })
    end

    context "when attributes are valid" do
      it "should destroy with no errors" do
        dynamo_stub.client.stub_responses(:delete_item, true)

        expect(dynamo_instance.destroy).to eq(true)
        expect(dynamo_instance.errors.empty?).to eq(true)
      end
    end

    context "when AWS returns a ServiceError" do
      it "should not attributes and return errors" do
        dynamo_stub.client.stub_responses(:delete_item, "ServiceError")

        dynamo_instance.destroy

        expect(dynamo_instance.errors).to eq(["stubbed-response-error-message"])
      end
    end
  end

  describe "self.find(h_key, r_key = nil)" do
    context "when a record is found" do
      it "should find a user setting and return a DynamodbRcord object" do
        dynamo_stub.client.stub_responses(:get_item, { item: result_data })
        tested_record = dynamo_stub.find(123)

        expect(tested_record.data).to eq(dynamo_instance.data)
      end
    end

    context "when record is not found" do
      it "should raise record not found" do
        dynamo_stub.client.stub_responses(:get_item, { item: nil })

        expect(dynamo_stub.find(123)).to eq({ error: "Not Found" })
      end
    end

    context "when AWS returns a ServiceError" do
      it "should raise record not found" do
        dynamo_stub.client.stub_responses(:get_item, "ServiceError")

        expect(dynamo_stub.find(123)).to eq({ error: "Not Found" })
      end
    end
  end

  describe "self.find_or_initialize_by(h_key, r_key = nil)" do
    context "when a record is found" do
      it "should find a user setting and return a DynamodbRcord object" do
        dynamo_stub.client.stub_responses(:get_item, { item: result_data })
        tested_record = dynamo_stub.find_or_initialize_by(123)

        expect(tested_record.data).to eq(dynamo_instance.data)
      end
    end

    context "when record is not found" do
      it "should initialize a new record" do
        dynamo_stub.client.stub_responses(:get_item, { item: nil })

        expect(dynamo_stub.find_or_initialize_by(123).new_record?).to eq(true)
      end
    end
  end

  describe "self.create(data)" do
    context "when data is valid" do
      it "should return with no errors" do
        dynamo_stub.client.stub_responses(:put_item, true)
        dynamodb_base = dynamo_stub.create(data)

        expect(dynamodb_base.errors.empty?).to eq(true)
        expect(dynamodb_base.data).to eq(result_data)
      end
    end

    context "when data is not valid" do
      let(:data) { { foo: "true" } }

      it "should return with validation errors" do
        dynamodb_base = dynamo_stub.create(data)

        expect(dynamodb_base.errors).to eq(["Incorrect format of data"])
      end
    end

    context "when AWS returns a ServiceError" do
      it "should return with errors" do
        dynamo_stub.client.stub_responses(:put_item, "ServiceError")
        dynamodb_base = dynamo_stub.create(data)

        expect(dynamodb_base.errors).to eq(["stubbed-response-error-message"])
      end
    end
  end
end
