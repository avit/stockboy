require 'stockboy/translator'

module Stockboy::Translations

  # Translate missing values to boolean true
  #
  # This is a useful fallback for translation errors from boolean fields.
  #
  # == Job template DSL
  #
  # Registered as +:or_true+. Use with:
  #
  #   attributes do
  #     active as: [:boolean, :or_true]
  #   end
  #
  # @example
  #   bool = Stockboy::Translator::Boolean.new
  #
  #   record.active = nil
  #   bool.translate(record, :active) # => true
  #
  #   record.active = false
  #   bool.translate(record, :active) # => false
  #
  #   record.active = true
  #   bool.translate(record, :active) # => true
  #
  class DefaultTrue < Stockboy::Translator

    # @return [Boolean]
    #
    def translate(context)
      value = field_value(context, field_key)

      return true if value.nil?
      return value
    end

  end
end
