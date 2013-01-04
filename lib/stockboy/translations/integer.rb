require 'stockboy/translator'

module Stockboy::Translations
  class Integer < Stockboy::Translator

    def translate(context)
      value = context.public_send field_key
      return nil if value.nil? || value == ""
      value.to_i
    end

  end
end
