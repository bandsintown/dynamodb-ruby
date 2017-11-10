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
  end

  describe ".client=(new_connection)" do
    it "sets the class variable for @@client" do
      dynamo_stub.client = "abc"

      expect(Dynamodb::Connection.class_variable_get(:@@client)).to eq("abc")
    end
  end

  describe ".reset_client" do
    it "resets @@client and @@resource back to nil" do
      dynamo_stub.reset_client

      expect(Dynamodb::Connection.class_variable_get(:@@client)).to eq(nil)
      expect(Dynamodb::Connection.class_variable_get(:@@resource)).to eq(nil)
    end
  end

  describe ".resource" do
    it "initializes a AWS DynamoDB Resource Connection" do
      expect(dynamo_stub.resource).to(
        eq(Dynamodb::Connection.class_variable_get(:@@resource))
      )
    end
  end

  describe ".resource=(new_resource)" do
    it "sets the class variable for @@resource" do
      dynamo_stub.resource = "abc"

      expect(Dynamodb::Connection.class_variable_get(:@@resource)).to eq("abc")
    end
  end
end
