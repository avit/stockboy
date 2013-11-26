module Stockboy

  # A hash for executing items in order with callbacks
  #
  class FilterChain < Hash

    # Initialize a new FilterChain with a hash of filters
    #
    # @param [Hash{Symbol=>Filter}] hash
    #
    def self.new(hash=nil)
      super().replace(hash || {})
    end

    # Add filters to the front of the chain
    #
    # @param [Hash{Symbol=>Filter}] hash Filters to add
    #
    def prepend(hash)
      replace hash.merge(self)
    end

    # Call the reset callback on all filters that respond to it
    #
    # @return [Hash{Symbol=>Array}] Filter keys point to empty arrays
    #
    def reset
      each do |key, filter|
        filter.reset if filter.respond_to? :reset
      end
      keys_to_arrays
    end

    # @return [Hash{Symbol=>Array}] Filter keys point to empty arrays
    #
    def keys_to_arrays
      Hash[keys.map { |k| [k, []] }]
    end

  end
end
