require 'stockboy/exceptions'
require 'stockboy/source_record'

module Stockboy
  class Translator

    attr_reader :field_key

    def initialize(key)
      @field_key = key
    end

    def call(context)
      translate(context)
    end

    private

    def translate(context)
      raise NoMethodError, "def #{self.class}#translate needs implementation"
    end

  end
end
