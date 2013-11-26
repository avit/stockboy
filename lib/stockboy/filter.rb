require 'stockboy/exceptions'

module Stockboy

  # Filters can be any callable object that returns true or false. This
  # abstract class is a helpful way to define a commonly used filter pattern.
  #
  # == Interface
  #
  # Filter subclasses must define a +filter+ method that returns true or false
  # when called with the record context.
  #
  # @example
  #   class Bouncer < Stockboy::Filter
  #     def initialize(age)
  #       @age = age
  #     end
  #     def filter(input_context, output_context)
  #       input_context["RawAge"].empty? or output_context.age < @age
  #     end
  #   end
  #
  #   Stockboy::Filters.register(:bouncer, Bouncer.new(19))
  #   filter :under_age, :bouncer # in job template
  #
  #   Stockboy::Filters.register(:check_id, Bouncer)
  #   filter :under_age, :bouncer, 19 # in job template
  #
  # @abstract
  #
  class Filter

    # Return true to capture a filtered record, false to pass it on
    #
    # @param [SourceRecord] raw_context
    #   Unmapped source fields with Hash-like access field names (e.g.
    #   <tt>input["RawField"]</tt>) or raw values on mapped attributes as
    #   methods (e.g. <tt>input.email</tt>)
    # @param [MappedRecord] translated_context
    #   Mapped and translated fields with access to attributes
    #   as methods (<tt>output.email</tt>)
    # @return [Boolean]
    #
    def call(raw_context, translated_context)
      return !!filter(raw_context, translated_context)
    end

    private

    # @abstract
    #
    def filter(raw_context, translated_context)
      raise NoMethodError, "#{self.class}#filter must be implemented"
    end

  end

end
