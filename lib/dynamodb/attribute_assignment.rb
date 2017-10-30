# frozen_string_literal: true

module Dynamodb
  module AttributeAssignment
    def self.included(base)
      base.extend ClassMethods
    end

    ATTRIBUTE_TYPES = {
      string: "S",
      number: "N",
      binary: "B"
    }

    KEY_TYPES = {
      hash: "HASH",
      range: "RANGE"
    }

    PROJECTION_TYPES = {
      all: "ALL",
      keys: "KEYS_ONLY",
      include: "INCLUDE"
    }

    def table_name
      self.class.table_name
    end

    def hash_key
      self.class.hash_key
    end

    def range_key
      self.class.range_key
    end

    def client
      self.class.client
    end

    def indexes
      self.class.indexes
    end

    def local_indexes
      self.class.local_indexes
    end

    def global_indexes
      self.class.global_indexes
    end

    module ClassMethods
      attr_reader :hash_key, :range_key, :attribute_definitions,
                  :key_schema, :indexes, :local_indexes, :global_indexes

      def table_name(_table_name = nil)
        return (@_table_name || name.tableize) if _table_name.nil?

        @_table_name = _table_name.to_s
      end

      def local_indexes
        indexes_for(:local)
      end

      def global_indexes
        indexes_for(:global)
      end

      def key(attr_name, attr_type, options)
        instance_variable_set("@#{options[:key]}_key", attr_name.to_s)
        define_attribute({ name: attr_name, type: attr_type })
        define_key_schema(attr_name, options[:key])
      end

      def local_index(options)
        @indexes ||= []
        @indexes << define_local_index(options)
        define_attribute(
          {
            name: options[:key][:name],
            type: options[:key][:type]
          }
        )
      end

      def global_index(options)
        @indexes ||= []
        @indexes << define_global_index(options)
        options[:keys].keys.each do |_key|
          define_attribute(
            {
              name: options[:keys][_key][:name],
              type: options[:keys][_key][:type]
            }
          )
        end
      end

      def time_to_live(&block)
        define_method :schedule_time_to_live, &block
      end

      private

      def define_attribute(name:, type:)
        @attribute_definitions ||= []
        attr_def = { attribute_name: name.to_s, attribute_type: ATTRIBUTE_TYPES[type] }
        @attribute_definitions << attr_def unless @attribute_definitions.include?(attr_def)
      end

      def define_key_schema(attr_name, key_type)
        @key_schema ||= []
        @key_schema << { attribute_name: attr_name.to_s, key_type: KEY_TYPES[key_type] }
      end

      def define_local_index(options)
        hash_key_schema =
          @key_schema.detect { |k| k[:attribute_name] == @hash_key }

        {
          type: :local,
          index_name: options[:name].to_s,
          key_schema: [
            hash_key_schema,
            { attribute_name: options[:key][:name].to_s, key_type: KEY_TYPES[:range] }
          ],
          projection: define_projection(options)
        }
      end

      def define_global_index(options)
        {
          type: :global,
          index_name: options[:name].to_s,
          key_schema: options[:keys].keys.each_with_object([]) do |_key, obj|
            obj << { attribute_name: options[:keys][_key][:name].to_s, key_type: KEY_TYPES[_key] }
          end,
          projection: define_projection(options)
        }
      end

      def define_projection(options)
        p_hash = {
          projection_type: PROJECTION_TYPES[options[:projection]]
        }

        p_hash.merge!({
          non_key_attributes: options[:attributes]
        }) if options[:projection] == :include

        p_hash
      end

      def indexes_for(type)
        return if @indexes.nil?

        @indexes.select { |h| h[:type] == type }
                .map { |h| h.select { |k| k != :type }}
      end
    end
  end
end
