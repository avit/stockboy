require 'stockboy/attribute'
require 'stockboy/translations'

module Stockboy

  # Table of attributes for finding corresponding field/attribute translations
  #
  class AttributeMap

    include Enumerable

    # @visibility private
    #
    class DSL
      def initialize(instance)
        @attribute_map = instance
      end

      def method_missing(attr, *args)
        @attribute_map.insert(attr, *args)
      end
    end

    # Initialize a new attribute map
    #
    def initialize(rows={}, &block)
      @map = rows
      @unmapped = Hash.new
      if block_given?
        DSL.new(self).instance_eval(&block)
      end
    end

    # Retrieve an attribute by symbolic name
    #
    # @param [Symbol] key
    # @return [Attribute]
    #
    def [](key)
      @map[key]
    end

    # Add or replace a mapped attribute
    #
    # @param [Symbol] key Name of the output attribute
    # @param [Hash] opts
    # @option opts [String] from Name of input field from reader
    # @option opts [Array,Proc,Translator] as One or more translators
    #
    def insert(key, opts={})
      to = key.to_sym
      from = opts.fetch(:from, key)
      from = from.to_s.freeze if from.is_a? Symbol
      translators = Array(opts[:as]).map { |t| Translations.translator_for(to, t) }
      ignore_condition = opts[:ignore]
      define_singleton_method(key) { @map[key] }
      @map[key] = Attribute.new(to, from, translators, ignore_condition)
    end

    # Fetch the attribute corresponding to the source field name
    #
    # @param [String] key
    # @return [Attribute]
    #
    def attribute_from(key)
      find { |a| a.from == key } or @unmapped[key] ||= Attribute.new(nil, key, nil)
    end

    # Enumerate over attributes
    #
    # @return [Enumerator]
    # @yieldparam [Attribute]
    #
    def each(*args, &block)
      @map.values.each(*args, &block)
    end

  end
end
