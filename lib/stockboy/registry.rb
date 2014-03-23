module Stockboy

  # Holds a collection of registered classes for convenient reference by
  # symbolic name
  #
  module Registry

    def self.extended(base)
      base.class_eval do
        @registry = {}
      end
    end

    # Register a class under a convenient symbolic name
    #
    # @param [Symbol] key      Symbolic name of the class
    # @param [Class]  provider Class to be returned when requested
    #
    def register(key, provider)
      @registry[key] = provider
    end

    # Look up a class and return it by symbolic name
    #
    # @param [Symbol] key
    # @return [Class]
    #
    def find(key)
      @registry[key]
    end
    alias_method :[], :find

    # List all named classes in the registry
    #
    # @return [Hash]
    #
    def all
      @registry
    end

    def build(key, options, block)
      options = [options] unless options.is_a? Array
      key = find(key) if key.is_a? Symbol
      key = key.new(*options, &block) if key.is_a? Class
      key
    end

  end
end
