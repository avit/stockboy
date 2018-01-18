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
      @ignored_fields = []
      freeze
    end

    # Convert the mapped output to a hash
    #
    # @return [Hash]
    #
    def to_hash
      bulk_hash.tap do |out|
        tmp_context = SourceRecord.new(out, @table)
        @map.each_with_object(out) do |col|
          out.delete(col.to) if ignore?(col, tmp_context)
        end
      end
    end
    alias_method :attributes, :to_hash

    # Mapped output hash including ignored values
    #
    # @return [Hash]
    #
    def bulk_hash
      Hash.new.tap do |out|
        @map.each { |col| out[col.to] = translate(col) }
      end
    end

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

    # Generate an md5 hash from the mapped output attributes
    #
    # @return [String] MD5 hash
    #
    def hash
      Digest::MD5.hexdigest(Marshal::dump(to_hash)).freeze
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
      SourceRecord.new(raw_hash, @table)
    end

    # Data structure representing the record's mapped & translated output values
    #
    # @return [MappedRecord]
    # @example
    #   input = candidate.output
    #   output.email       # => "me@example.com"
    #
    def output
      MappedRecord.new(bulk_hash)
    end

    private

    def translate(col)
      @tr_table.fetch(col.to) do |key|
        return @tr_table[key] = sanitize(@table[col.from]) if col.translators.empty?
        fields = raw_hash
        tr_input = col.translators.reduce(input) do |value, tr|
          begin
            fields[key] = tr[value]
            SourceRecord.new(fields, @table)
          rescue
            translation_error = TranslationError.new(key, self)
            fields[key] = Stockboy.configuration.translation_error_handler.call(translation_error)
            break SourceRecord.new(fields, @table)
          end
        end
        @tr_table[key] = tr_input.public_send(key)
      end
    end

    def ignore?(col, context)
      return true if @ignored_fields.include? col.to
      if col.ignore?(context)
        @ignored_fields << col.to
        true
      else
        false
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
