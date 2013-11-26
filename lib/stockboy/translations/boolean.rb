require 'stockboy/translator'

module Stockboy::Translations

  # Convert common false-like and true-like values to proper boolean +true+ or
  # +false+.
  #
  # Biased towards +true+ for unrecognized values. See {FALSY_VALUES} for the
  # recognized list of values.
  #
  # == Job template DSL
  #
  # Registered as +:boolean+. Use with:
  #
  #   attributes do
  #     active as: :boolean
  #   end
  #
  # @example
  #   bool = Stockboy::Translator::Boolean.new
  #
  #   record.active = 't'
  #   bool.translate(record, :active) # => true
  #
  #   record.active = 'f'
  #   bool.translate(record, :active) # => false
  #
  #   record.active = '1'
  #   bool.translate(record, :active) # => true
  #
  #   record.active = '0'
  #   bool.translate(record, :active) # => false
  #
  #   record.active = 'y'
  #   bool.translate(record, :active) # => true
  #
  #   record.active = 'n'
  #   bool.translate(record, :active) # => false
  #
  class Boolean < Stockboy::Translator
    FALSY_VALUES = [0, '', '0', 'f', 'F', 'false', 'FALSE', 'n', 'N', 'no', 'NO']

    # @return [Boolean]
    #
    def translate(context)
      value = field_value(context, field_key)

      return !! value && !FALSY_VALUES.include?(value)
    end

  end
end
