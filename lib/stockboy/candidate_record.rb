require 'stockboy/attribute_map'
require 'stockboy/mapped_record'
require 'stockboy/source_record'
require 'stockboy/translations'

module Stockboy
  class CandidateRecord

    def initialize(attrs, map)
      @map = map
      @table = attrs.to_hash.symbolize_keys
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
      return @table[col.from] if col.translators.empty?
      tr_table = col.translators.inject(OpenStruct.new(raw_hash)) do |m,t|
        begin
          new_value = t.call(m)
        rescue # maybe there's a tighter way to catch translation errors here
          m.public_send "#{col.to}=", nil
          break m
        end
        m.tap { |n| n.public_send("#{col.to}=", new_value) }
      end
      tr_table.public_send col.to
    end

  end
end
