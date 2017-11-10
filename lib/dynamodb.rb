# frozen_string_literal: true

require "dynamodb/version"
require "dynamodb/connection"
require "dynamodb/table_actions"

module Dynamodb
  extend Connection
  extend TableActions

  # class << self
  #   attr_accessor :configuration
  # end
  #
  # def self.configure
  #   self.configuration ||= Configuration.new
  #   yield(configuration)
  # end
  #
  # class Configuration
  # attr_accessor :client_settings, :resource_settings
  #
  #   def initialize
  #     @client_settings = {}
  #     @resource_settings = {}
  #   end
  # end
end
