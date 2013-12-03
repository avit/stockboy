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
        @instance = instance
        @map = @instance.instance_variable_get(:@map)
      end

      def method_missing(attr, *args)
        opts = args.first || {}
        to = attr.to_sym
        from = opts.fetch(:from, attr)
        from = from.to_s.freeze if from.is_a? Symbol
        translators = Array(opts[:as]).map { |t| Translations.translator_for(to, t) }
        @map[attr] = Attribute.new(to, from, translators)
        define_attribute_method(attr)
      end

      def define_attribute_method(attr)
        (class << @instance; self end).send(:define_method, attr) { @map[attr] }
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
      freeze
    end

    # Retrieve an attribute by symbolic name
    #
    # @param [Symbol] key
    # @return [Attribute]
    #
    def [](key)
      @map[key]
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
