require 'stockboy/attribute'
require 'stockboy/translations'

module Stockboy
  class AttributeMap

    include Enumerable

    class DSL
      def initialize(instance)
        @instance = instance
        @map = @instance.instance_variable_get(:@map)
      end

      def method_missing(attr, *args)
        opts = args.first || {}
        to = attr.to_sym
        from = opts.fetch(:from, attr)
        from = from.to_sym if from.respond_to?(:to_sym)
        translators = Array(opts[:as]).map { |t| Translations.translator_for(to, t) }
        @map[attr] = Attribute.new(to, from, translators)
        (class << @instance; self end).send(:define_method, attr) { @map[attr] }
      end
    end

    def initialize(rows={}, &block)
      @map = rows
      if block_given?
        DSL.new(self).instance_eval(&block)
      end
      freeze
    end

    def [](key)
      @map[key.to_sym]
    end

    def each(*args, &block)
      @map.values.each(*args, &block)
    end

  end
end
