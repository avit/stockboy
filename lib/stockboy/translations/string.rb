require 'stockboy/translator'

module Stockboy::Translations
  class String < Stockboy::Translator

    def translate(context)
      value = field_value(context, field_key)
      return "" if value.blank?

      value.strip
    end

  end
end
