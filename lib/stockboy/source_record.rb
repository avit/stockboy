require 'stockboy/mapped_record'

module Stockboy
  class SourceRecord < MappedRecord
    def initialize(mapped_fields, data_fields)
      @data_fields = data_fields
      super(mapped_fields)
    end

    def [](key)
      @data_fields[key.to_s]
    end
  end
end
