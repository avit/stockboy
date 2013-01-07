require 'stockboy/translator'

module Stockboy::Translations
  class Integer < Stockboy::Translator

    def translate(context)
      value = field_value(context)
      return nil if value.blank?
      value.to_i
    end

  end
end
