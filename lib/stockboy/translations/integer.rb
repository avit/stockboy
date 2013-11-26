require 'stockboy/translator'

module Stockboy::Translations

  # Translate string values to +Fixnum+
  #
  # == Job template DSL
  #
  # Registered as +:integer+. Use with:
  #
  #   attributes do
  #     children as: :integer
  #   end
  #
  # @example
  #   num = Stockboy::Translator::Integer.new
  #
  #   record.children = "2"
  #   num.translate(record, :children) # => 2
  #
  class Integer < Stockboy::Translator

    # @return [Fixnum]
    #
    def translate(context)
      value = field_value(context, field_key)
      return nil if value.blank?

      value.to_i
    end

  end
end
