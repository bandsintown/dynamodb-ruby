# frozen_string_literal: true

module Dynamodb
  module TableActions
    def get_item(_table_name, _key, options = {})
      _item = client.get_item(
        {
          table_name: _table_name,
          key: _key
        }.merge!(options)
      )[:item]

      _item ? item_to_object(_item) : nil
    end

    def put_item(_table_name, _item, options = {})
      client.put_item(
        {
          table_name: _table_name,
          item: _item
        }.merge!(options)
      )
    end

    def delete_item(_table_name, _key, options = {})
      client.delete_item(
        {
          table_name: _table_name,
          key: _key
        }.merge!(options)
      )
    end

    def _query(opts)
      result = client.query(opts)
      result.items = result.items.map { |x| item_to_object(x) }
      result
    end

    def describe_table(_table_name)
      client.describe_table(table_name: _table_name)
    end

    def list_tables
      client.list_tables.table_names
    end

    def delete_table(_table_name)
      # To prevent accidentally deleting tables in production
      (raise "Can't delete tables in production") unless self.class.name == "Dynamodb" &&
        self.config == { endpoint: "http://localhost:10070" }

      client.delete_table(table_name: _table_name)
    end

    def create_table(_table_name, options)
      # To prevent accidentally creating tables in production
      (raise "Can't create tables in production") unless self.class.name == "Dynamodb" &&
        self.config == { endpoint: "http://localhost:10070" }

      resource.create_table(
        {
          table_name: _table_name,
          provisioned_throughput: {
            read_capacity_units: 5,
            write_capacity_units: 5,
          }
        }.merge!(options)
      )
    end

    private

    # Converts a hash item result from dynamodb to object
    def item_to_object(_item)
      self.new(_item)
    end
  end
end
