require 'stockboy/translator'

module Stockboy::Translations

  # Translate missing values to empty string
  #
  # This is a useful fallback for translation errors.
  #
  # == Job template DSL
  #
  # Registered as +:or_empty+. Use with:
  #
  #   attributes do
  #     product_code as: [->(r){raise "Invalid"}, :or_empty]
  #   end
  #
  # @example
  #   str = Stockboy::Translator::DefaultEmptyString.new
  #
  #   record.product_code = "ITEM"
  #   str.translate(record, :product_code) # => "ITEM"
  #
  #   record.product_code = nil
  #   str.translate(record, :product_code) # => ""
  #
  class DefaultEmptyString < Stockboy::Translator

    # @return [String]
    #
    def translate(context)
      value = field_value(context, field_key)
      return "" if (value).blank?

      return value
    end

  end
end
