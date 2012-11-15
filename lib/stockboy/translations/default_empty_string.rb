require 'stockboy/translator'

module Stockboy::Translations
  class DefaultEmptyString < Stockboy::Translator

    def translate(context)
      return "" if context[field_key].nil?
      return context[field_key]
    end

  end
end
