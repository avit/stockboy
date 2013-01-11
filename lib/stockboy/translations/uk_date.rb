require 'stockboy/translator'

module Stockboy::Translations

  # Parses numeric dates provided in UK (DMY) order:
  #
  # * DD-MM-YYYY
  # * DD-MM-YY
  # * DD/MM/YYYY
  # * DD/MM/YY
  #
  class UKDate < Stockboy::Translator

    def translate(context)
      value = field_value(context, field_key)
      return nil if value.blank?

      ::Date.strptime(value, date_format(value))
    end

    def date_format(value)
      x = value.include?(?/) ? ?/ : ?-
      if value =~ %r"\d{1,2}(?:/|-)\d{1,2}(?:/|-)\d{2}$"
        "%d#{x}%m#{x}%y"
      else
        "%d#{x}%m#{x}%Y"
      end
    end
  end
end
