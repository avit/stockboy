require 'stockboy/translator'

module Stockboy::Translations
  class DefaultEmptyString < Stockboy::Translator

    def translate(context)
      value = field_value(context, field_key)
      return "" if (value).blank?

      return value
    end

  end
end
