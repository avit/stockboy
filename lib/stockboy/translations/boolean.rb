require 'stockboy/translator'

module Stockboy::Translations

  # Convert common false-like and true-like values to proper boolean +true+ or
  # +false+.
  #
  # Returns nil for indeterminate values. This should be chained with a
  # default value translator like [DefaultFalse] or [DefaultTrue].
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
  #   record.active = '?'
  #   bool.translate(record, :active) # => nil
  #
  class Boolean < Stockboy::Translator
    TRUTHY_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'y', 'Y', 'yes', 'YES']
    FALSY_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE', 'n', 'N', 'no', 'NO']

    # @return [Boolean]
    #
    def translate(context)
      value = field_value(context, field_key)

      return true if TRUTHY_VALUES.include?(value)
      return false if FALSY_VALUES.include?(value)
      return nil
    end

  end
end
