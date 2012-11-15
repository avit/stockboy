require 'stockboy/translator'

module Stockboy::Translations
  class Date < Stockboy::Translator

    def translate(context)
      return nil if context[field_key] == ""
      ::Date.parse(context[field_key])
    end

  end
end
