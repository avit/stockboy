require 'stockboy/translator'

module Stockboy::Translations

  # Translates numeric dates provided in US (MDY) order
  #
  # Priority is given to middle-endian (US) order:
  #
  # * MM-DD-YYYY
  # * MM-DD-YY
  # * MM/DD/YYYY
  # * MM/DD/YY
  #
  # == Job template DSL
  #
  # Registered as +:us_date+. Use with:
  #
  #   attributes do
  #     check_in as: :us_date
  #   end
  #
  # @example
  #   date = Stockboy::Translator::USDate.new
  #
  #   record.check_in = "2-1-12"
  #   date.translate(record, :check_in) # => #<Date 2012-02-01>
  #
  class USDate < Stockboy::Translator

    # @return [Date]
    #
    def translate(context)
      value = field_value(context, field_key)
      return nil if value.blank?

      ::Date.strptime(value, date_format(value))
    end

    private

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
