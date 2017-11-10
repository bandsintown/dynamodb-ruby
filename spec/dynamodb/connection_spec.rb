# frozen_string_literal: true

require "spec_helper"
require "test_classes/dynamodb_stub"

RSpec.describe Dynamodb::Connection do
  let(:dynamo_stub) { DynamodbStub }
  # NOTE: Need to reset the Dynamodb::Connection for testing
  before(:each) do
    dynamo_stub.reset_client
  end

  describe "class instance variables" do
    it "sets @@client to nil" do
      expect(Dynamodb::Connection.class_variable_get(:@@client)).to eq(nil)
    end

    it "sets @@resource to nil" do
      expect(Dynamodb::Connection.class_variable_get(:@@resource)).to eq(nil)
    end
  end

  describe ".client" do
    it "initializes a AWS DynamoDB Client Connection" do
      expect(dynamo_stub.client).to(
        eq(Dynamodb::Connection.class_variable_get(:@@client))
      )
    end

    context "when setting a new connection" do
      it "assigns a new connection to client" do
        dynamo_stub.client("new connection")

        expect(Dynamodb::Connection.class_variable_get(:@@client)).to(
          eq("new connection")
        )
      end
    end
  end

  describe ".resource" do
    it "initializes a AWS DynamoDB Resource Connection" do
      expect(dynamo_stub.resource).to(
        eq(Dynamodb::Connection.class_variable_get(:@@resource))
      )
    end

    context "when setting a new resource" do
      it "assigns a new connection to resource" do
        dynamo_stub.resource("new resource")

        expect(Dynamodb::Connection.class_variable_get(:@@resource)).to(
          eq("new resource")
        )
      end
    end
  end

  describe ".reset_client" do
    it "resets @@client and @@resource back to nil" do
      dynamo_stub.reset_client

      expect(Dynamodb::Connection.class_variable_get(:@@client)).to eq(nil)
      expect(Dynamodb::Connection.class_variable_get(:@@resource)).to eq(nil)
    end
  end
end
