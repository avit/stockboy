require 'stockboy/dsl'

module Stockboy

  # Abstract class for defining data readers
  #
  # == Interface
  #
  # A reader must implement a +parse+ method for extracting an array of records
  # from raw data. At this stage no data transformation is performed, only
  # extracting field tokens for each record, based on the specific data
  # serialization.
  #
  # String keys should be preferred, since these may be specified by the user;
  # external inputs should not be symbolized (because symbols are never GC'd).
  # Frozen strings for keys are a good idea, of course.
  #
  # @example
  #   reader.parse("name,email\nArthur Dent,arthur@example.com")
  #   # => [{"name" => "Arthur Dent", "email" => "arthur@example.com"}]
  #
  # @abstract
  #
  class Reader
    extend Stockboy::DSL

    # Initialize a new reader
    #
    # @param [Hash] opts
    #
    def initialize(opts={})
      @encoding = opts.delete(:encoding)
    end

    # Take raw input (String) and extract an array of records
    #
    # @return [Array<Hash>]
    #
    def parse(data)
      raise NoMethodError, "#{self.class}#parse needs implementation"
    end

  end


  # @!macro [new] reader.skip_row_options
  # [skip_header_rows]
  #   If the file has a preamble before actual data to be ignored
  #     skip_header_rows 4
  # [skip_header_rows]
  #   If the file has a summary or footer to be ignored
  #     skip_footer_rows 4

  # @!macro [new] reader.encoding_options
  # [encoding]
  #   String encoding format of the source data. All readers output UTF-8.
  #     encoding 'Windows-1252'

end
