require 'stockboy/registry'

module Stockboy

  # Registry of available named filters
  #
  module Filters
    extend Stockboy::Registry

    def self.build(callable, args)
      if callable.is_a?(Symbol)
        callable = find(callable)
        callable = callable.new(*args) if callable.is_a? Class
      end
      callable
    end

  end

end
