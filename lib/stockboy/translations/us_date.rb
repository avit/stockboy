require 'stockboy/translator'

module Stockboy::Translations
  class USDate < Stockboy::Translator

    def translate(context)
      value = context[field_key]
      return nil if value == "" || value.nil?
      ::Date.strptime(value, "%m/%d/%Y")
    end

  end
end
