require 'stockboy/translator'

module Stockboy::Translations

  # Translate missing values to boolean false
  #
  # This is a useful fallback for translation errors from boolean fields.
  #
  # == Job template DSL
  #
  # Registered as +:or_false+. Use with:
  #
  #   attributes do
  #     active as: [:boolean, :or_false]
  #   end
  #
  # @example
  #   bool = Stockboy::Translator::Boolean.new
  #
  #   record.active = nil
  #   bool.translate(record, :active) # => false
  #
  #   record.active = false
  #   bool.translate(record, :active) # => false
  #
  #   record.active = true
  #   bool.translate(record, :active) # => true
  #
  class DefaultFalse < Stockboy::Translator

    # @return [Boolean]
    #
    def translate(context)
      value = field_value(context, field_key)

      return false if value.nil?
      return value
    end

  end
end
