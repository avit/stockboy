require 'stockboy/provider'

module Stockboy
  class ProviderRepeater

    YIELD_ONCE = proc { |output, provider| output << provider }

    attr_reader :base_provider
    attr_reader :data_size
    attr_reader :data_time

    def initialize(provider, &yielder)
      @orig_provider = provider
      @base_provider = provider.dup
      @yielder = yielder || YIELD_ONCE
    end

    def data
      # return base_provider.data unless block_given?
      return nil unless block_given?
      each do |nth_provider|
        yield fetch_iteration_data(nth_provider)
      end
    end

    def clear
      @base_provider = @orig_provider.dup
      @data_time, @data_size = nil, nil
      super
    end

    def each
      return to_enum unless block_given?
      enum = to_enum
      while true
        begin
          provider = enum.next
          unless provider.respond_to? :data
            raise ArgumentError, "expected Provider, got #{provider.class}"
          end
        rescue StopIteration
          return provider
        end
        yield provider
        provider.clear
      end
    end

    def to_enum
      Enumerator.new do |y|
        begin
          @yielder.call(y, base_provider)
        rescue LocalJumpError
          raise $!, "use output << provider instead of yield", $!.backtrace
        end
      end
    end

    private

    def method_missing(method, *args, &block)
      base_provider.public_send(method, *args, &block)
    end

    def fetch_iteration_data(provider)
      if provider.data
        @data_size = [@data_size, provider.data_size].compact.reduce(&:+)
        @data_time = [@data_time, provider.data_time].compact.max
      end
      provider.data
    end

  end
end
