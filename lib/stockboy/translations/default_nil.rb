require 'stockboy/translator'

module Stockboy::Translations
  class DefaultNil < Stockboy::Translator

    def translate(context)
      value = context[field_key]
      return nil if (value).blank?

      return value
    end

  end
end
