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
      @table = reuse_frozen_hash_keys(attrs, map)
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
      @tr_table.fetch(col.to) do |key|
        return @tr_table[key] = sanitize(@table[col.from]) if col.translators.empty?
        fields = raw_hash
        tr_input = col.translators.reduce(input) do |value, tr|
          begin
            fields[col.to] = tr[value]
            SourceRecord.new(fields, @table)
          rescue
            fields[col.to] = nil
            break SourceRecord.new(fields, @table)
          end
        end
        @tr_table[col.to] = tr_input.public_send(col.to)
      end
    end

    # Clean output values that are a subclass of a standard type
    #
    def sanitize(value)
      case value
      when String # e.g. Nori::StringWithAttributes
        value.to_s
      else
        value
      end
    end

    # Optimization to reuse the same hash key string instances
    #
    # The need for this is fixed for CSV in: https://bugs.ruby-lang.org/issues/9143
    # (ruby >= 2.1) and can be managed by applying str.freeze in other readers.
    #
    def reuse_frozen_hash_keys(attrs, map)
      return attrs unless attrs.is_a? Hash
      attrs.reduce(Hash.new) do |new_hash, (field, value)|
        key = map.attribute_from(field).from
        new_hash[key] = value
        new_hash
      end
    end

  end
end
