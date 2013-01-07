require 'stockboy/translator'

module Stockboy::Translations
  class Time < Stockboy::Translator

    def translate(context)
      value = context[field_key]
      return nil if (value).blank?

      clock.parse(value).to_time
    end

    private

    def clock
      ::Time.respond_to?(:zone) && ::Time.zone || ::DateTime
    end

  end
end
