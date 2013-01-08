require 'stockboy/translator'

module Stockboy::Translations
  class DefaultZero < Stockboy::Translator

    def translate(context)
      value = field_value(context, field_key)
      return 0 if value.blank?

      return value
    end

  end
end
