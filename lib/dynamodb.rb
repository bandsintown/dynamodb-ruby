# frozen_string_literal: true

require "dynamodb/version"
require "dynamodb/connection"
require "dynamodb/table_actions"

module Dynamodb
  extend Connection
  extend TableActions
end
