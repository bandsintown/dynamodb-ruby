# frozen_string_literal: true

require "dynamodb/configuration"
require "dynamodb/connection"
require "dynamodb/table_actions"
require "dynamodb/version"

module Dynamodb
  extend Connection
  extend TableActions

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
