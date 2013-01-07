require 'stockboy/translator'

module Stockboy::Translations
  class Date < Stockboy::Translator

    def translate(context)
      value = context[field_key]
      return nil if value.blank?

      case value
      when String then ::Date.parse(value)
      when ::Time, ::DateTime then ::Date.new(value.year, value.month, value.day)
      when ::Date then value
      else nil
      end
    end

  end
end
