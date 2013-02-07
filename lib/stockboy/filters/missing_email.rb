require 'stockboy/filter'
module Stockboy::Filters
  class MissingEmail < Stockboy::Filter

    def initialize(attr)
      @attr = attr
    end

    # Very loose matching to check if there is a potential email-like string.
    # Does not do any format checking.
    #
    def filter(raw,output)
      value = output.send(@attr)
      return true if value.blank?
      return true unless value =~ /\w@\w/
    end

  end
end
