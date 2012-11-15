require 'stockboy/translator'

module Stockboy::Translations
  class DefaultZero < Stockboy::Translator

    def translate(context)
      value = context[field_key]
      return 0 if value.nil? || value.to_s.empty?
      return context[field_key]
    end

  end
end
