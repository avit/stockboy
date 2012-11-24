require 'stockboy/translator'

module Stockboy::Translations
  class Integer < Stockboy::Translator

    def translate(context)
      value = context[field_key]
      return nil if value.nil? || value == ""
      context[field_key].to_i
    end

  end
end
