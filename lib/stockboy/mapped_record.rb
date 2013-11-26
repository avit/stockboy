module Stockboy

  # This represents the "output" side of a {CandidateRecord}
  #
  # Based on the current attribute map, it will have reader methods for the
  # output values of each attribute. This is similar to an OpenStruct, but
  # more efficient since we cache the defined methods.
  #
  # @example
  #   output = MappedRecord.new(first_name: "Zaphod")
  #   output.first_name # => "Zaphod"
  #
  class MappedRecord

    # This is an optimization to avoid relying on method_missing.
    #
    # This module holds a pool of already-defined accessor methods for sets of
    # record attributes. Each set of methods is held in a module that gets
    # extended into new MappedRecords.
    #
    # @visibility private
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

    # Initialize a new MappedRecord
    #
    # @param [Hash<Symbol>] fields
    #   Keys map to reader methods
    #
    def initialize(fields)
      mod = AccessorMethods.for(fields.keys)
      extend mod
      @fields = fields
      freeze
    end

    # @return [String]
    #
    def to_s
      @fields.to_s
    end

  end
end
