require 'stockboy/mapped_record'

module Stockboy
  class SourceRecord < MappedRecord
    def initialize(mapped_fields, data_fields)
      @data_fields = data_fields
      super(mapped_fields)
    end

    def [](key)
      key = key.to_sym if key.respond_to?(:to_sym)
      @data_fields[key]
    end
  end
end
