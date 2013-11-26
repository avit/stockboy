require 'stockboy/exceptions'
require 'stockboy/source_record'

module Stockboy

  # This is an abstract class to help set up common named translations
  #
  # A Translator receives a source record and transforms selected attributes to
  # another format or type. The entire record context is passed to the
  # translator so that other fields can be compared, split, or recombined
  # (instead of just getting the single attribute value without context)
  #
  # == Interface
  #
  # To implement a translator type, you must:
  #
  # * Initialize with the attribute name to which it applies.
  # * Implement a +translate+ method that returns the value for the attribute
  #   it is transforming.
  # * Use +field_value(context, field_key)+ to access the input value in the
  #   translate method.
  #
  # @abstract
  #
  class Translator

    # Field from the record context to which the translation will apply
    #
    attr_reader :field_key

    # Initialize a new translator for an attribute
    #
    # @param [Symbol] key Mapped attribute name to be translated
    #
    def initialize(key)
      @field_key = key
    end

    # Perform translation on a record attribute
    #
    # @param [SourceRecord, MappedRecord, Hash] context
    #   The record to which the translation will be applied
    #
    def call(context)
      context = OpenStruct.new(context) if context.is_a? Hash
      translate(context)
    end

    # String representation for a more helpful representation
    #
    def inspect
      "#<#{self.class.name||'Stockboy::Translator'} (#{@field_key})>"
    end

    private

    def field_value(context, field_key)
      context.send field_key if context.respond_to? field_key
    end

    def translate(context)
      raise NoMethodError, "def #{self.class}#translate needs implementation"
    end

  end
end
