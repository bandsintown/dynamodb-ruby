module Dynamodb
  class Configuration
  attr_accessor :client_config, :can_create_tables, :can_delete_tables

    def initialize
      @client_config = { stub_responses: true }
      @can_create_tables = false
      @can_delete_tables = false
    end
  end
end
