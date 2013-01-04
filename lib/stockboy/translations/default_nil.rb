require 'stockboy/translator'

module Stockboy::Translations
  class DefaultNil < Stockboy::Translator

    def translate(context)
      return nil if (val = context.public_send field_key).to_s.empty?
      return val
    end

  end
end
