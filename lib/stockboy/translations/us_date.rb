require 'stockboy/translator'

module Stockboy::Translations

  # Parses numeric dates provided in American (MDY) order:
  #
  # * MM-DD-YYYY
  # * MM-DD-YY
  # * MM/DD/YYYY
  # * MM/DD/YY
  #
  class USDate < Stockboy::Translator

    def translate(context)
      value = context.public_send field_key
      return nil if value == "" || value.nil?
      ::Date.strptime(value, date_format(value))
    end

    def date_format(value)
      x = value.include?(?/) ? ?/ : ?-
      if value =~ %r"\d{1,2}(?:/|-)\d{1,2}(?:/|-)\d{4}"
        "%m#{x}%d#{x}%Y"
      else
        "%m#{x}%d#{x}%y"
      end
    end
  end
end
