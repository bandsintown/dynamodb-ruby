# frozen_string_literal: true

require "dynamodb"
require "dynamodb_schema"

module Dynamodb
  class Local
    extend DynamoDBSchema

    class << self
      attr_reader :dynamodb

      def init_dynamodb
        @dynamodb ||= Dynamodb
        # Note: Set database to point to dynamodb local
        @dynamodb.config = { endpoint: "http://localhost:10070" }
        @dynamodb.reset_client # reset the connection
      end

      def reset
        init_dynamodb

        teardown
        build_tables # DynamoDBSchema#build_tables
      rescue => e
        splat_error("Unable to reset DynamoDB:", e.message)
      end

      def teardown
        @dynamodb.list_tables.each do |table|
          @dynamodb.delete_table(table)
        end
      rescue => e
        splat_error("Unable to teardown DynamoDB tables:", e.message)
      end

      def create_table(table_name, klass, &block)
        params = build_table_attrs(klass)
        params.merge!(yield) if block_given? # merge overrides
        @dynamodb.create_table(table_name, params)
      rescue Aws::DynamoDB::Errors => e
        splat_error("Unable to create DynamoDB tables:", e.message)
      end

      def build_table_attrs(klass)
        params =
          {
            attribute_definitions: klass.attribute_definitions,
            key_schema: klass.key_schema,
            provisioned_throughput: provisioned_throughput
          }

        params.merge!(
          local_secondary_indexes: klass.local_indexes
        ) unless klass.local_indexes.empty?

        unless klass.global_indexes.empty?
          global_indexes_hash = klass.global_indexes.map do |x|
            x.merge({ provisioned_throughput: provisioned_throughput })
          end
          params.merge!(
            global_secondary_indexes: global_indexes_hash
          )
        end

        params
      end

      def provisioned_throughput
        {
          read_capacity_units: 10,
          write_capacity_units: 10
        }
      end

      def splat_error(title, message)
        puts <<-HEREDOC
          ##############################

          #{title}

          #{message}

          ##############################
        HEREDOC
      end
    end
  end
end
