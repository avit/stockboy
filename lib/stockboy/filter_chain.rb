module Stockboy
  class FilterChain < Hash

    def self.new(hash=nil)
      super().replace(hash || {})
    end

    def prepend(hash)
      replace hash.merge(self)
    end

    def reset(records={})
      each do |key, filter|
        filter.reset if filter.respond_to? :reset
      end
      keys_to_arrays
    end

    def keys_to_arrays
      Hash[keys.map { |k| [k, []] }]
    end

  end
end
