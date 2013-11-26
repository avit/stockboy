require 'stockboy/translator'

module Stockboy::Translations

  # Convert numeric strings to +BigDecimal+
  #
  # == Job template DSL
  #
  # Registered as +:decimal+. Use with:
  #
  #   attributes do
  #     check_in as: :decimal
  #   end
  #
  # @example
  #   dec = Stockboy::Translator::Date.new
  #
  #   record.cost = "256.99"
  #   dec.translate(record, :cost) # => #<BigDecimal 256.99>
  #
  class Decimal < Stockboy::Translator

    # @return [BigDecimal]
    #
    def translate(context)
      value = field_value(context, field_key)
      return nil if value.blank?

      BigDecimal.new(value, 10)
    end

  end
end
