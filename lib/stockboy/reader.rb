require 'stockboy/dsl'

module Stockboy
  class Reader

    attr_accessor :encoding

    def initialize(opts={})
      @encoding = opts[:encoding]
    end

  end
end
