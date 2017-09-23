require 'stockboy/translator'

module Stockboy::Translations

  # Translate missing values to numeric zero
  #
  # This is a useful fallback for translation errors.
  #
  # == Job template DSL
  #
  # Registered as +:or_zero+. Use with:
  #
  #   attributes do
  #     cost as: [->(r){raise "Invalid"}, :or_zero]
  #   end
  #
  # @example
  #   zero = Stockboy::Translator::DefaultZero.new
  #
  #   record.cost = 256
  #   zero.translate(record, :cost) # => 256
  #
  #   record.cost = nil
  #   zero.translate(record, :cost) # => 0
  #
  #   record.cost = ""
  #   zero.translate(record, :cost) # => 0
  #
  class DefaultZero < Stockboy::Translator

    # @return [Integer]
    #
    def translate(context)
      value = field_value(context, field_key)
      return 0 if value.blank?

      return value
    end

  end
end
