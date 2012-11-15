require 'stockboy/exceptions'
require 'stockboy/translator'

module Stockboy
  module Translations

    @translators ||= {}

    class << self
      def register(name, callable)
        if callable.respond_to?(:call) or callable < Stockboy::Translator
          @translators[name.to_sym] = callable
        else
          raise ArgumentError, "Registered translators must be callable"
        end
      end

      def translate(func_name, context)
        translator_for(:value, func_name).call(context)
      end

      def find(func_name)
        @translators[func_name]
      end
      alias_method :[], :find

      def translator_for(attr, lookup)
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
end
