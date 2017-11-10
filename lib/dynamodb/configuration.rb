module Dynamodb
  class Configuration
  attr_accessor :client_config

    def initialize
      @client_config = { stub_responses: true }
    end
  end
end
