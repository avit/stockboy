require 'stockboy/filter'

module Stockboy::Filters

  # Very loose matching to pre-screen missing emails.
  #
  # Only checks if there is a potential email-like string in the output value,
  # and does not do any format checking for validity.
  #
  # @example
  #   filter = Stockboy::Filters::MissingEmail.new(:addr)
  #   model.email = ""
  #   filter.call(_, model) # => false
  #   model.email = "@"
  #   filter.call(_, model) # => true
  #
  class MissingEmail < Stockboy::Filter

    # Initialize a new filter for a missing email attribute
    #
    # @param [Symbol] attr
    #   Name of the email attribute to examine on the mapped output record
    #
    def initialize(attr)
      @attr = attr
    end

    private

    def filter(raw,output)
      value = output.send(@attr)
      return true if value.blank?
      return true unless value =~ /\w@\w/
    end

  end
end
