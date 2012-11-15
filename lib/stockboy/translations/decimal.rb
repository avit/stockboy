require 'stockboy/translator'

module Stockboy::Translations
  class Decimal < Stockboy::Translator

    def translate(context)
      value = context[field_key]
      return nil if value.nil? || value.empty?
      BigDecimal.new(context[field_key],10)
    end

  end
end
