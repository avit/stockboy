module Stockboy
  module StringPool

    def with_string_pool
      @string_pool = []
      result = yield
      @string_pool = []
      result
    end

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
