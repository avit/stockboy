require 'stockboy/translator'

module Stockboy::Translations

  # Convert ISO-8601 and other recognized date-like strings to +Date+
  #
  # == Job template DSL
  #
  # Registered as +:date+. Use with:
  #
  #   attributes do
  #     check_in as: :date
  #   end
  #
  # @example
  #   date = Stockboy::Translator::Date.new
  #
  #   record.check_in = "2012-01-01"
  #   date.translate(record, :check_in) # => #<Date 2012-01-01>
  #
  #   record.check_in = "Jan 1, 2012"
  #   date.translate(record, :check_in) # => #<Date 2012-01-01>
  #
  class Date < Stockboy::Translator

    # @return [Date]
    #
    def translate(context)
      value = field_value(context, field_key)
      return nil if value.blank?

      case value
      when ::String then parse_date(value.strip)
      when ::Time, ::DateTime then ::Date.new(value.year, value.month, value.day)
      when ::Date then value
      else nil
      end
    end

    private

    # Generic parse action, overridden by subclasses
    # @return [Date]
    #
    def parse_date(value)
      ::Date.parse(value)
    end

    module PatternMatching
      private

      module ClassMethods
        def match(*patterns)
          @patterns = patterns
        end
        attr_reader :patterns
      end

      def self.included(base)
        base.extend ClassMethods
      end

      # Match date strings with 4-digit year
      MATCH_YYYY = %r"\A\d{1,2}(/|-)\d{1,2}\1\d{4}\z"
      SLASH = '/'.freeze

      # @return [Date]
      #
      def parse_date(value)
        ::Date.strptime(value, date_format(value))
      end

      def date_format(value)
        self.class.patterns[yy_index(value) + sep_index(value)].freeze
      end

      def yy_index(value)
        value =~ MATCH_YYYY ? 0 : 2
      end

      def sep_index(value)
        value.include?(SLASH) ? 1 : 0
      end
    end

  end
end
