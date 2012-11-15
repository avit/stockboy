module Stockboy
  module Registry

    def self.extended(base)
      base.class_eval do
        @registry = {}
      end
    end

    def register(key, provider)
      @registry[key] = provider
    end

    def find(key)
      @registry[key]
    end
    alias_method :[], :find

    def all
      @registry
    end

  end
end
