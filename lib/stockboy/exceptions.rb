module Stockboy
  class OutOfSequence < StandardError; end

  # TranslationError is a wrapper to store the standard error as well as the key and record which caused it
  class TranslationError < StandardError 

     def initialize (key, record)
      @key = key
      @record = record
     end

     def message
      "Attribute [#{key}] caused #{cause.message}"
     end

     attr_reader :key
     attr_reader :record

    end
end
