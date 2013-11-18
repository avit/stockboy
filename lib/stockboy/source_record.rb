require 'stockboy/mapped_record'

module Stockboy
  class SourceRecord < MappedRecord
    def initialize(mapped_fields, data_fields)
      @data_fields = data_fields
      super(mapped_fields)
    end

    def [](key)
      key = key.to_s if key.is_a? Symbol
      @data_fields[key]
    end
  end
end
