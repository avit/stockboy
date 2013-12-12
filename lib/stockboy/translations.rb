require 'stockboy/exceptions'
require 'stockboy/registry'
require 'stockboy/translator'

module Stockboy

  # Registry of available {Translator} classes for lookup by symbolic name in the
  # job template DSL.
  #
  module Translations
    extend Stockboy::Registry

    # Register a translator under a convenient symbolic name
    #
    # @param [Symbol] name
    #   Symbolic name of the class
    # @param [Translator, #call] callable
    #   Translator class or any callable object
    #
    def self.register(name, callable)
      if callable.respond_to?(:call) or callable < Stockboy::Translator
        @registry[name.to_sym] = callable
      else
        raise ArgumentError, "Registered translators must be callable"
      end
    end

    # Calls a named translator for the raw value
    #
    # @param [Symbol, Translator, #call] func_name
    #   Symbol representing a registered translator, or an actual translator
    # @param [SourceRecord, MappedRecord, Hash, String] context
    #   Collection of fields or the raw value to which the translation is applied
    #
    def self.translate(func_name, context)
      translator_for(:value, func_name).call(context)
    end

    # Prepare a translator for a given attribute
    #
    # @param [Symbol] attr
    #   Name of the mapped record attribute to address for translation
    # @param [Symbol, #call] lookup
    #   Symbolic translator name or callable object
    # @return [Translator] instance
    #
    def self.translator_for(attr, lookup)
      if lookup.respond_to?(:call)
        lookup
      elsif tr = self[lookup]
        tr.is_a?(Class) && tr < Stockboy::Translator ? tr.new(attr) : tr
      else
        ->(context) { context.public_send attr } # no-op
      end
    end

  end
end
