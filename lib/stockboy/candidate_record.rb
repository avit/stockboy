require 'stockboy/attribute_map'
require 'stockboy/mapped_record'
require 'stockboy/source_record'
require 'stockboy/translations'

module Stockboy
  class CandidateRecord

    def initialize(attrs, map)
      @map = map
      @table = attrs.to_hash.symbolize_keys
      @tr_table = Hash.new
      freeze
    end

    def to_hash
      Hash.new.tap do |out|
        @map.each { |col| out[col.to] = translate(col) }
      end
    end
    alias_method :attributes, :to_hash

    def raw_hash
      Hash.new.tap do |out|
        @map.each { |col| out[col.to] = @table[col.from] }
      end
    end
    alias_method :raw_attributes, :raw_hash

    def to_model(model)
      model.new(attributes)
    end

    def partition(filters={})
      input, output = self.input, self.output
      filters.each_pair do |filter_key, f|
        if f.call(input, output)
          return filter_key
        end
      end
      nil
    end

    def input
      SourceRecord.new(self.raw_hash, @table)
    end

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

  end
end
