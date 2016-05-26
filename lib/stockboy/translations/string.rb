require 'stockboy/translator'

module Stockboy::Translations

  # Cleans string values by stripping surrounding whitespace
  #
  # == Job template DSL
  #
  # Registered as +:string+. Use with:
  #
  #   attributes do
  #     name as: :string
  #   end
  #
  # @example
  #   str = Stockboy::Translator::String.new
  #
  #   record.name = "Arthur  "
  #   str.translate(record, :name) # => "Arthur"
  #
  class String < Stockboy::Translator

    # @return [String]
    #
    def translate(context)
      value = field_value(context, field_key)
      return "" if value.nil?

      value.to_s.strip
    end

  end
end
