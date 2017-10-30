# frozen_string_literal: true

require "aws-sdk-dynamodb"

module Dynamodb
  module Connection
    def client
      @@client ||= Aws::DynamoDB::Client.new(config)
    end

    def client=(new_connection)
      @@client = new_connection
    end

    def reset_client
      @@client   = nil
      @@resource = nil
    end

    def resource
      @@resource ||= Aws::DynamoDB::Resource.new(client: client)
    end

    def resource=(new_resource)
      @@resource = new_resource
    end

    def config
      @@config ||= { endpoint: "http://localhost:10070" }
    end

    def config=(client_config)
      @@config = client_config
    end
  end
end
