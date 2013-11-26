require 'stockboy/translator'

module Stockboy::Translations

  # Convert ISO-8601 and other recognized date-like strings to +Date+
  #
  # == Job template DSL
  #
  # Registered as +:date+. Use with:
  #
  #   attributes do
  #     check_in as: :date
  #   end
  #
  # @example
  #   date = Stockboy::Translator::Date.new
  #
  #   record.check_in = "2012-01-01"
  #   date.translate(record, :check_in) # => #<Date 2012-01-01>
  #
  #   record.check_in = "Jan 1, 2012"
  #   date.translate(record, :check_in) # => #<Date 2012-01-01>
  #
  class Date < Stockboy::Translator

    # @return [Date]
    #
    def translate(context)
      value = field_value(context, field_key)
      return nil if value.blank?

      case value
      when ::String then ::Date.parse(value)
      when ::Time, ::DateTime then ::Date.new(value.year, value.month, value.day)
      when ::Date then value
      else nil
      end
    end

  end
end
