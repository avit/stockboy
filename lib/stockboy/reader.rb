require 'stockboy/dsl_attributes'

module Stockboy
  class Reader
    extend Stockboy::DSLAttributes

    dsl_attrs :encoding

    def initialize(opts={})
      @encoding = opts[:encoding]
    end

  end
end
