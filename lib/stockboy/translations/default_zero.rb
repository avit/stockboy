require 'stockboy/translator'

module Stockboy::Translations
  class DefaultZero < Stockboy::Translator

    def translate(context)
      value = context.public_send field_key
      return 0 if value.nil? || value.to_s.empty?
      return value
    end

  end
end
