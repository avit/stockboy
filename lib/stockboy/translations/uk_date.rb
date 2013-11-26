require 'stockboy/translator'

module Stockboy::Translations

  # Translates numeric dates provided in UK (DMY) order
  #
  # Priority is given to small-endian (UK) order:
  #
  # * DD-MM-YYYY
  # * DD-MM-YY
  # * DD/MM/YYYY
  # * DD/MM/YY
  #
  # == Job template DSL
  #
  # Registered as +:uk_date+. Use with:
  #
  #   attributes do
  #     check_in as: :uk_date
  #   end
  #
  # @example
  #   date = Stockboy::Translator::UKDate.new
  #
  #   record.check_in = "1/2/12"
  #   date.translate(record, :check_in) # => #<Date 2012-02-01>
  #
  class UKDate < Stockboy::Translator

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
      if value =~ %r"\d{1,2}(?:/|-)\d{1,2}(?:/|-)\d{2}$"
        "%d#{x}%m#{x}%y"
      else
        "%d#{x}%m#{x}%Y"
      end
    end

  end
end
