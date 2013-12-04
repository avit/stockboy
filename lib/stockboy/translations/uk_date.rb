require 'stockboy/translator'
require 'stockboy/translations/us_date'

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
  class UKDate < Stockboy::Translations::USDate

    private

    def date_format(value)
      x = separator(value)
      value =~ MATCH_YYYY ? "%d#{x}%m#{x}%Y" : "%d#{x}%m#{x}%y"
    end

  end
end
