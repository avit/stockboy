require 'stockboy/translator'

module Stockboy::Translations
  class DefaultNil < Stockboy::Translator

    def translate(context)
      return nil if context[field_key].to_s.empty?
      return context[field_key]
    end

  end
end
