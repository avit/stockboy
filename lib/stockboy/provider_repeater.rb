require 'stockboy/provider'

module Stockboy
  class ProviderRepeater

    YIELD_ONCE = proc { |output, provider| output << provider }

    ProviderStats = Struct.new(:data_time, :data_size, :data?) do
      def self.from(provider)
        new(provider.data_time, provider.data_size, provider.data?)
      end
    end

    attr_reader :base_provider

    def initialize(provider, &yielder)
      @orig_provider = provider
      @base_provider = provider.dup
      @iterations = []
      @yielder = yielder || YIELD_ONCE
    end

    # Determine if there was any returned data after processing iterations
    # @param [:all?,:any?,:one?] reduction
    #   Specify if all iterations must return data to be valid, or just any
    #
    def data?(reduction = :all?)
      return nil if data_iterations == 0
      @iterations.send(reduction, &:data?)
    end

    # Get the total data size returned after processing iterations
    #
    def data_size
      @iterations.reduce(nil) { |sum, source|
        source.data_size ? source.data_size + sum.to_i : sum
      }
    end

    # Get the last data time returned after processing iterations
    #
    def data_time
      @iterations.reduce(nil) { |max, source|
        source.data_time && (max.nil? || source.data_time > max) ? source.data_time : max
      }
    end

    def data_iterations
      @iterations.size
    end

    def data
      unless block_given?
        raise ArgumentError, "expect a block for yielding data iterations"
      end

      each do |nth_provider|
        yield fetch_iteration_data(nth_provider)
      end
    end

    def clear
      @base_provider = @orig_provider.dup
      @iterations.clear
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
        @iterations << ProviderStats.from(provider)
      end
      provider.data
    end

  end
end
