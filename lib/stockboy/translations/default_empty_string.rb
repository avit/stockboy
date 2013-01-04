require 'stockboy/translator'

module Stockboy::Translations
  class DefaultEmptyString < Stockboy::Translator

    def translate(context)
      return "" if (val = context.public_send field_key).nil?
      return val
    end

  end
end
