require 'stockboy/exceptions'

module Stockboy

  # Filters operate on a struct of remapped fields
  #
  class Filter

    # return true to filter out a record
    def call(raw_context, translated_context)
      return !!filter(raw_context, translated_context)
    end

    private

    def filter(raw_context, translated_context)
      raise NoMethodError, "#{self.class}#filter must be implemented"
    end

  end

end
