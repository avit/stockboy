require 'stockboy/exceptions'
require 'stockboy/translator'

module Stockboy
  module Translations

    @registry ||= {}

    def self.register(name, callable)
      if callable.respond_to?(:call) or callable < Stockboy::Translator
        @registry[name.to_sym] = callable
      else
        raise ArgumentError, "Registered translators must be callable"
      end
    end

    def self.translate(func_name, context)
      translator_for(:value, func_name).call(context)
    end

    def self.translator_for(attr, lookup)
      if lookup.respond_to?(:call)
        lookup
      elsif tr = self[lookup]
        tr.is_a?(Class) && tr < Stockboy::Translator ? tr.new(attr) : tr
      else
        ->(context) { context.public_send attr } # no-op
      end
    end

    def self.find(func_name)
      @registry[func_name]
    end
    class << self
      alias_method :[], :find
    end

  end
end
