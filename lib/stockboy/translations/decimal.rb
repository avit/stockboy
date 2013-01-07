require 'stockboy/translator'

module Stockboy::Translations
  class Decimal < Stockboy::Translator

    def translate(context)
      value = field_value(context)
      return nil if value.blank?
      BigDecimal.new(value, 10)
    end

  end
end
