require 'stockboy/exceptions'

module Stockboy
  class Translator

    attr_reader :field_key

    def initialize(key)
      @field_key = key
    end

      if context.is_a?(OpenStruct)
        context = context.instance_variable_get(:@table)
      end
    def call(context)
      translate(context)
    end

    private

    def field_value(context)
      context.public_send(field_key)
    end

    def filter_empty_string?(str)
      not str.nil? || str.empty?
    end

    def translate(context)
      raise NoMethodError, "def #{self.class}#translate needs implementation"
    end

  end
end
