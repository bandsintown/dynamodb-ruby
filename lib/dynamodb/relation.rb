# frozen_string_literal: true

# Builds a Query for the DynamoDB table.
#
# @param [Object] source DynamoDB table object

module Dynamodb
  class Relation
    attr_accessor :source, :consistent_read, :scan_index_forward
    attr_reader :index_name, :key_condition_expression, :filter_expression,
                :expression_attribute_names, :expression_attribute_values,
                :filter_expression, :projection_expression,
                :attribute_expressors, :offset_key

    OPERATOR_MAP = {
      eq:           "=",
      gt:           ">",
      gte:          ">=",
      lt:           "<",
      lte:          "<=",
      begins_with:  "begins_with",
      between:      "BETWEEN"
    }.freeze

    QUERY_METHODS = [
      :index_name, :consistent_read, :scan_index_forward,
      :key_condition_expression, :filter_expression, :expression_attribute_names,
      :expression_attribute_values, :projection_expression, :exclusive_start_key
    ].freeze

    QUERY_INSTANCE_VARS = [
      :limit
    ].freeze

    def initialize(source)
      @source = source
      @attribute_expressors = {}
      @consistent_read = false
      @scan_index_forward = true
    end

    def where(args)
      args.each do |k, v|
        setter = "#{k}=".to_sym
        self.has_method?(setter) ? self.send(setter, v) : add_attribute_query(k,v)
      end
      build_expressions
      self
    end

    def limit(int)
      @_limit = int
      build_expressions
      self
    end

    def select(*args)
      @projection_expression = args.flatten
      build_expressions
      self
    end

    def all
      source._query(build_query)
    end

    def to_query
      build_query
    end

    def query(args = {})
      source._query(args)
    end

    def key_condition_expression
      @key_condition_expression.join(" AND ")
    end

    def filter_expression
      @filter_expression.join(" AND ")
    end

    def projection_expression
      return nil if @projection_expression.nil?

      @projection_expression.join(", ")
    end

    def exclusive_start_key
      @offset_key
    end

    protected

    def has_method?(meth)
      self.class.private_method_defined?(meth)
    end

    def not_empty?(val)
      !!val == val || !val.to_s.strip.empty?
    end

    private

    # Can be set to nil
    def index_name=(val)
      @index_name = val.nil? ? val : val.to_s
    end

    # Builds the exclusive_start_key if val is a Hash
    def offset_key=(val)
      @offset_key = val.stringify_keys if val.is_a?(Hash)
    end

    def build_query
      query = {}
      query.merge!({ table_name: source.table_name })
      build_expressions
      QUERY_METHODS.each do |meth|
        val = self.send(meth)
        query.merge!({ meth => val }) if not_empty?(val)
      end
      QUERY_INSTANCE_VARS.each do |var|
        val = self.instance_variable_get("@_#{var.to_s}")
        query.merge!({ var => val }) if not_empty?(val)
      end
      query
    end

    def add_attribute_name(name)
      ni = @expression_attribute_names.size + 1
      @expression_attribute_names.merge!({ "#n#{ni}" => name })
      "#n#{ni}"
    end

    def add_attribute_value(values)
      values = [values].flatten # Set to an array to handle BETWEEN operator
      values.each_with_object([]) do |value, obj|
        vi = @expression_attribute_values.size + 1
        @expression_attribute_values.merge!({ ":v#{vi}" => value })
        obj << ":v#{vi}"
      end.join(" AND ")
    end

    def add_attribute_query(attr, val)
      @attribute_expressors.merge!({ attr => val })
    end

    def build_expressions
      reset_expressions

      attribute_expressors.each do |k, v|
        expression_type = _define_expression_type(k).to_sym
        self.send(expression_type, k, v)
      end
    end

    def reset_expressions
      @expression_attribute_names = {}
      @expression_attribute_values = {}
      @key_condition_expression = []
      @filter_expression = []
    end

    def _hash_expression=(k, v)
      h_name = add_attribute_name(k.to_s)
      h_value = add_attribute_value(v)
      @key_condition_expression << "#{h_name} = #{h_value}"
    end

    def _range_expression=(k, v)
      r_name = add_attribute_name(k.to_s)
      r_op = OPERATOR_MAP[v.keys[0]]
      r_value = add_attribute_value(v.values[0])
      @key_condition_expression << "#{r_name} #{r_op} #{r_value}"
    end

    def _filter_expression=(k, v)
      f_name = add_attribute_name(k.to_s)
      f_op = OPERATOR_MAP[v.keys[0]]
      f_value = add_attribute_value(v.values[0])
      @filter_expression << "#{f_name} #{f_op} #{f_value}"
    end

    def _define_expression_type(key)
      schema = _expression_schema.detect { |x| x[:attribute_name] == key.to_s }
      schema ? "_#{schema[:key_type].downcase}_expression=" : "_filter_expression="
    end

    def _expression_schema
      return source.key_schema if index_name.nil?

      index = source.indexes.detect { |x| x[:index_name] == index_name }
      index[:key_schema]
    end
  end
end
