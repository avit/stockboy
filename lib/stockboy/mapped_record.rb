module Stockboy
  class MappedRecord
    def initialize(fields)
      @fields = fields
      @fields.keys.each do |k|
        instance_eval "def #{k}; @fields[:#{k}] end"
      end
      freeze
    end

    def to_s
      @fields
    end
  end
end
