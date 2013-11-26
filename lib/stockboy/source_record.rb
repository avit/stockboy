require 'stockboy/mapped_record'

module Stockboy

  # This represents the raw "input" side of a {CandidateRecord}
  #
  # It provides access to the original field values before mapping or
  # translation as hash keys.
  #
  # @example
  #   input = SourceRecord.new(
  #       {check_in: "2012-12-12"},
  #       {"RawCheckIn" => "2012-12-12"})
  #
  #   input["RawCheckIn"] # => "2012-12-12"
  #   input.check_in # => "2012-12-12"
  #
  class SourceRecord < MappedRecord

    # Initialize a new instance
    #
    # @param [Hash{Symbol=>Object}] mapped_fields
    #   Represents the raw values mapped to the final attribute names
    # @param [Hash] data_fields
    #   The raw input fields with original key values
    #
    def initialize(mapped_fields, data_fields)
      @data_fields = data_fields
      super(mapped_fields)
    end

    # Access a raw field value by the original input field name
    #
    # @param [String] key
    #
    def [](key)
      key = key.to_s if key.is_a? Symbol
      @data_fields[key]
    end

  end

end
