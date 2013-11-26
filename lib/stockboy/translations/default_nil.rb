require 'stockboy/translator'

module Stockboy::Translations

  # Translate missing values to empty string
  #
  # This is a useful fallback for translation errors.
  #
  # == Job template DSL
  #
  # Registered as +:or_nil+. Use with:
  #
  #   attributes do
  #     product_code as: [->(r){raise "Invalid"}, :or_nil]
  #   end
  #
  # @example
  #   str = Stockboy::Translator::DefaultNil.new
  #
  #   record.product_code = "ITEM"
  #   str.translate(record, :product_code) # => "ITEM"
  #
  #   record.product_code = ""
  #   str.translate(record, :product_code) # => nil
  #
  class DefaultNil < Stockboy::Translator

    # @return [Object, NilClass]
    #
    def translate(context)
      value = field_value(context, field_key)
      return nil if (value).blank?

      return value
    end

  end
end
