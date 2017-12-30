module Stockboy
  class OutOfSequence < StandardError; end

  class TranslationError < StandardError

    def initialize (key, record)
      @key = key
      @record = record
      @cause = $!
    end

    def message
      reason = @cause && @cause.message || super
      "Attribute [#{key}] caused #{reason}"
    end

    def backtrace
      @cause && @cause.backtrace || super
    end

    attr_reader :key
    attr_reader :record
  end

  class DSLEnvVariableUndefined < StandardError; end
end
