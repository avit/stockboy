require 'stockboy/reader'

module Stockboy::Readers
  class XML < Stockboy::Reader

    def initialize(opts={}, &block)
      @xml_options = opts
      instance_eval &block if block_given?
    end

    def parse(data)
      response.body
    end
  end
end
