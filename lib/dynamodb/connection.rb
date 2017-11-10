# frozen_string_literal: true

require "aws-sdk-dynamodb"

module Dynamodb
  module Connection
    def client(new_connection = nil)
      return (@@client = new_connection) unless new_connection.nil?

      @@client ||= Aws::DynamoDB::Client.new(Dynamodb.configuration.client_config)
    end

    def resource(new_resource = nil)
      return (@@resource = new_resource) unless new_resource.nil?

      @@resource ||= Aws::DynamoDB::Resource.new(client: client)
    end

    def reset_client
      @@client   = nil
      @@resource = nil
    end
  end
end
