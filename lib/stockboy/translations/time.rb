require 'stockboy/translator'

module Stockboy::Translations
  class Time < Stockboy::Translator

    def translate(context)
      return nil if context[field_key] == ""
      clock.parse(context[field_key]).to_time
    end

    private

    def clock
      ::Time.respond_to?(:zone) && ::Time.zone || ::DateTime
    end

  end
end
