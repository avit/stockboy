require 'stockboy/translator'
require 'stockboy/translations/date'

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
  class USDate < Stockboy::Translations::Date
    include Stockboy::Translations::Date::PatternMatching

    match '%m-%d-%Y', '%m/%d/%Y', '%m-%d-%y', '%m/%d/%y'

  end
end
