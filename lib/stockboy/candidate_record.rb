require 'stockboy/attribute_map'
require 'stockboy/mapped_record'
require 'stockboy/source_record'
require 'stockboy/translations'

module Stockboy

  # Joins the raw data values to an attribute mapping to allow comparison of
  # input/output values, conversion, and filtering
  #
  class CandidateRecord

    # Initialize a new candidate record
    #
    # @param [Hash] attrs Raw key-values from source data
    # @param [AttributeMap] map Mapping and translations
    #
    def initialize(attrs, map)
      @map = map
      @table = use_frozen_keys(attrs, map)
      @tr_table = Hash.new
      freeze
    end

    # Convert the mapped output to a hash
    #
    # @return [Hash]
    #
    def to_hash
      Hash.new.tap do |out|
        @map.each { |col| out[col.to] = translate(col) }
      end
    end
    alias_method :attributes, :to_hash

    # Return the original values mapped to attribute keys
    #
    # @return [Hash]
    #
    def raw_hash
      Hash.new.tap do |out|
        @map.each { |col| out[col.to] = @table[col.from] }
      end
    end
    alias_method :raw_attributes, :raw_hash

    # Wrap the mapped attributes in a new ActiveModel or ActiveRecord object
    #
    # @param [Class] model ActiveModel class
    # @return [Class] ActiveModel class
    #
    def to_model(model)
      model.new(attributes)
    end

    # Find the filter key that captures this record
    #
    # @param [FilterChain] filters List of filters to apply
    # @return [Symbol] Name of the matched filter
    #
    def partition(filters={})
      input, output = self.input, self.output
      filters.each_pair do |filter_key, f|
        if f.call(input, output)
          return filter_key
        end
      end
      nil
    end

    # Data structure representing the record's raw input values
    #
    # Values can be accessed like hash keys, or attribute names that correspond
    # to a +:from+ attribute mapping option
    #
    # @return [SourceRecord]
    # @example
    #   input = candidate.input
    #   input["RawEmail"] # => "ME@EXAMPLE.COM  "
    #   input.email       # => "ME@EXAMPLE.COM  "
    #
    def input
      SourceRecord.new(self.raw_hash, @table)
    end

    # Data structure representing the record's mapped & translated output values
    #
    # @return [MappedRecord]
    # @example
    #   input = candidate.output
    #   output.email       # => "me@example.com"
    #
    def output
      MappedRecord.new(self.to_hash)
    end

    private

    def translate(col)
      return sanitize(@table[col.from]) if col.translators.empty?
      return @tr_table[col.to] if @tr_table.has_key? col.to
      fields = self.raw_hash.dup
      translated = col.translators.inject(input) do |m,t|
        begin
          new_value = t.call(m)
        rescue
          fields[col.to] = nil
          break SourceRecord.new(fields, @table)
        end

        fields[col.to] = new_value
        SourceRecord.new(fields, @table)
      end
      @tr_table[col.to] = translated.public_send(col.to)
    end

    def sanitize(value)
      value.is_a?(String) ? value.to_s : value
    end

    def use_frozen_keys(attrs, map)
      attrs.reduce(Hash.new) do |new_hash, (field, value)|
        key = map.attribute_from(field).from
        new_hash[key] = value
        new_hash
      end
    end

  end
end
