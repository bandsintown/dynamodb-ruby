# frozen_string_literal: true

require "dynamodb/relation"
require "dynamodb/table_actions"

module Dynamodb
  module Querying
    extend TableActions

    def self.included(base)
      base.extend ClassMethods
      base.extend TableActions
    end

    def update(attributes = {})
      # Stringify keys for updated attributes - data consistency
      @data.deep_merge!(attributes.deep_stringify_keys)

      return false unless valid?

      generate_timestamps
      self.class.put_item(table_name, @data)
      true
    rescue Aws::DynamoDB::Errors::ServiceError => e
      handle_error(e)
      false
    end

    def save
      return false unless valid?

      generate_timestamps
      self.class.put_item(table_name, @data)
      true
    rescue Aws::DynamoDB::Errors::ServiceError => e
      handle_error(e)
      false
    end

    def destroy
      _keys = self.class._key_definitions(@data[hash_key], @data[range_key])
      self.class.delete_item(table_name, _keys)
      true
    rescue Aws::DynamoDB::Errors::ServiceError => e
      handle_error(e)
      false
    end

    module ClassMethods
      def find(h_key, r_key = nil)
        get_item(table_name, _key_definitions(h_key, r_key)) || not_found
      rescue Aws::DynamoDB::Errors::ServiceError => e
        not_found
      end

      def find_or_initialize_by(h_key, r_key = nil)
        response = find(h_key, r_key)
        response.is_a?(Hash) ? new(_key_definitions(h_key, r_key)) : response
      end

      def create(data = {}, conditions = {})
        object = new(data)

        return object unless object.valid?
        # TODO: Need to test conditions - condition_expressions
        object.generate_timestamps
        put_item(table_name, object.data, conditions)

        object
      rescue Aws::DynamoDB::Errors::ServiceError => e
        object.handle_error(e)
        object
      end

      # Build up a chain in response to a method
      # TODO: Need to write tests
      [:where, :limit, :select, :all, :query, :to_query].each do |meth|
        define_method(meth) do |*args|
          chain = Dynamodb::Relation.new(self)
          args ? chain.send(meth, *args) : chain.send(meth)
        end
      end

      def _key_definitions(h_value, r_value = nil)
        attrs = { hash_key => h_value }
        attrs.merge!({ range_key => r_value }) if r_value
        attrs
      end
    end
  end
end
