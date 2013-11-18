module Stockboy
  class MappedRecord

    # This module holds a pool of already-defined accessor methods for
    # attribute maps. It avoids a dependency on method_missing.
    #
    module AccessorMethods
      def self.for(attrs)
        @module_registry        ||= Hash.new
        @module_registry[attrs] ||= build_module(attrs)
      end

      def self.build_module(attr_accessor_keys)
        Module.new do
          attr_accessor_keys.each do |key|
            define_method key do
              @fields[key]
            end
          end
        end
      end
    end

    def initialize(fields)
      mod = AccessorMethods.for(fields.keys)
      extend mod
      @fields = fields
      freeze
    end

    def to_s
      @fields.to_s
    end
  end
end
