# frozen_string_literal: true

require "dynamodb/connection"
require "dynamodb/attribute_assignment"
require "dynamodb/querying"

##
# Represents a data hash object that is can be stored in a DynamoDB
#   NoSql Database.
module Dynamodb
  class Base
    extend Connection
    include AttributeAssignment
    include Querying

    attr_accessor :data
    attr_reader :errors

    def initialize(data = {}, new_record = true)
      self.data = data
      @new_record = new_record
      @errors = []
    end

    def data=(val)
      @data = val.deep_stringify_keys
    end

    def data
      normalize_hash_key # otherwise returns a BigDecimal
      @data.with_indifferent_access
    end

    def new_record?
      @new_record.nil? ? false : @new_record
    end

    def valid?
      # Checks to make sure the data is in the proper format and includes the
      #   hash_key Primary Key, and range_key if has one
      # TODO need to validate data is a hash earlier
      #   @data = 'a string'
      @errors = [] # start fresh
      return true if valid_data_format? && valid_hash_key? && valid_range_key?

      @errors << "Incorrect format of data"
      false # is not valid
    end

    def handle_error(e)
      @errors << e.message
    end

    def add_error(e)
      @errors << e
    end

    def generate_timestamps
      self&.schedule_time_to_live
      @data["updated_at"] = Time.now.utc.iso8601
      @data["created_at"] = Time.now.utc.iso8601 if new_record?
    end

    private

    def normalize_hash_key
      return unless @data[hash_key].is_a? BigDecimal
      @data[hash_key] = @data[hash_key].to_i
    end

    def valid_data_format?
      data.is_a? Hash
    end

    def valid_hash_key?
      data.key?(hash_key)
    end

    def valid_range_key?
      return true if range_key.nil?
      data.key?(range_key)
    end

    def self.not_found
       { error: "Not Found" }
    end
  end
end
