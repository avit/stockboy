require 'stockboy/translator'

module Stockboy::Translations
  class Integer < Stockboy::Translator

    def translate(context)
      return nil if context[field_key] == ""
      context[field_key].to_i
    end

  end
end
