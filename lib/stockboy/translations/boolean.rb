require 'stockboy/translator'

module Stockboy::Translations
  class Boolean < Stockboy::Translator
    FALSY_VALUES = [0, '', '0', 'f', 'F', 'false', 'FALSE', 'n', 'N', 'no', 'NO']

    def translate(context)
      value = field_value(context, field_key)

      return !! value && !FALSY_VALUES.include?(value)
    end

  end
end
