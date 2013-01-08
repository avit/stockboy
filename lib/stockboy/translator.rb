require 'stockboy/exceptions'
require 'stockboy/source_record'

module Stockboy
  class Translator

    attr_reader :field_key

    def initialize(key)
      @field_key = key
    end

    def call(context)
      context = OpenStruct.new(context) if context.is_a? Hash
      translate(context)
    end

    private

    def field_value(context, field_key)
      context.send field_key if context.respond_to? field_key
    end

    def translate(context)
      raise NoMethodError, "def #{self.class}#translate needs implementation"
    end

  end
end
