require 'stockboy/translator'

module Stockboy::Translations
  class DefaultNil < Stockboy::Translator

    def translate(context)
      value = field_value(context)
      return nil if (value).blank?
      return value
    end

  end
end
