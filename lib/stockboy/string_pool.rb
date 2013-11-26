module Stockboy

  # Holds frozen strings for shared lookup between different object instances
  #
  # @visibility private
  #
  module StringPool

    # Pass a block to yield a new string pool context around a group of
    # actions that should share the same string key instances
    #
    # @yield
    #
    def with_string_pool
      @string_pool = []
      result = yield
      @string_pool = []
      result
    end

    # Look up duplicate strings and return the shared frozen string
    #
    # @return [String]
    #
    def string_pool(name)
      if i = @string_pool.index(name)
        @string_pool[i]
      else
       @string_pool << name.freeze
       name
      end
    end

  end
end
