require 'stockboy/reader'

module Stockboy::Readers
  class XML < Stockboy::Reader

    dsl_attrs :elements

    def initialize(opts={}, &block)
      @xml_options = opts
      instance_eval &block if block_given?
    end

    def parse(response)
      response.to_array(*@elements)
    end
  end
end
