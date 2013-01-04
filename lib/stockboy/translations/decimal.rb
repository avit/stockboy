require 'stockboy/translator'

module Stockboy::Translations
  class Decimal < Stockboy::Translator

    def translate(context)
      value = context.public_send field_key
      return nil if value.nil? || value.empty?
      BigDecimal.new(value, 10)
    end

  end
end
