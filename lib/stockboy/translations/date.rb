require 'stockboy/translator'

module Stockboy::Translations
  class Date < Stockboy::Translator

    def translate(context)
      return nil if context[field_key] == ""
      val = context[field_key]
      case val
      when ::Date then val
      when String then ::Date.parse(val)
      when ::Time then ::Date.new(val.year, val.month, val.day)
      else nil
      end
    end

  end
end
