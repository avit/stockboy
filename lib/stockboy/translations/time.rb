require 'stockboy/translator'

module Stockboy::Translations
  class Time < Stockboy::Translator

    def translate(context)
      return nil if (value = context.public_send field_key) == ""
      clock.parse(value).to_time
    end

    private

    def clock
      ::Time.respond_to?(:zone) && ::Time.zone || ::DateTime
    end

  end
end
