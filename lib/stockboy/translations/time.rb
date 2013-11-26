require 'stockboy/translator'

module Stockboy::Translations

  # Convert ISO-8601 and other recognized time-like strings to +Time+
  #
  # Uses +ActiveSupport::TimeWithZone+ if available.
  #
  # == Job template DSL
  #
  # Registered as +:time+. Use with:
  #
  #   attributes do
  #     arriving as: :time
  #   end
  #
  # @example
  #   time = Stockboy::Translator::Time.new
  #
  #   record.arriving = "2012-01-01 12:34:56 UTC"
  #   time.translate(record, :arriving) # => #<Time 2012-01-01 12:34:56>
  #
  class Time < Stockboy::Translator

    # @return [Time]
    #
    def translate(context)
      value = field_value(context, field_key)
      return nil if (value).blank?

      clock.parse(value).to_time
    end

    private

    def clock
      ::Time.respond_to?(:zone) && ::Time.zone || ::DateTime
    end

  end
end
