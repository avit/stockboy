require 'stockboy/reader'
require 'stockboy/configuration'

module Stockboy::Readers

  # For reading fixed-width data split by column widths
  #
  class FixedWidth < Stockboy::Reader

    # @!group Options

    # Widths of data columns with optional names
    #
    # Array format will use numeric indexes for field keys. Hash will use the
    # keys for naming the fields.
    #
    # @return [Array<Integer>, Hash{Object=>Integer}]
    # @example
    #   reader.headers = [10, 5, 10, 42]
    #   reader.parse(data)
    #   #=> [{0=>"Arthur", 1=>"42", 2=>"Earth", 3=>""}]
    #
    #   reader.headers = {name: 10, age: 5, planet: 10, notes: 42}
    #   reader.parse(data)
    #   #=> [{name: "Arthur", age: "42", planet: "Earth", notes: ""}]
    #
    dsl_attr :headers

    # String format used for unpacking rows
    #
    # This is read from the {#headers} attribute by default but can be
    # overridden. Uses implementation from +String#unpack+ to set field widths
    # and types.
    #
    # @return [String]
    # @see http://ruby-doc.org/core/String.html#method-i-unpack
    # @example
    #   row_format "U16U32" # column A: 16 unicode, column B: 32 unicode
    #
    dsl_attr :row_format, attr_reader: false

    # Number of file rows to skip from start of file
    #
    # Useful if the file starts with a preamble or header metadata
    #
    # @return [Integer]
    #
    dsl_attr :skip_header_rows

    # Number of file rows to skip at end of file
    #
    # Useful if the file ends with a summary or notice
    #
    # @return [Integer]
    #
    dsl_attr :skip_footer_rows

    # Override original file encoding
    #
    # @return [String]
    #
    dsl_attr :encoding

    # @!endgroup

    # Initialize a new fixed-width reader
    #
    # @param [Hash] opts
    # @option opts [Array<Integer>, Hash<Integer>] headers
    # @option opts [Integer] skip_header_rows
    # @option opts [Integer] skip_footer_rows
    # @option opts [String] encoding
    #
    def initialize(opts={}, &block)
      super
      @headers          = opts[:headers]
      @skip_header_rows = opts.fetch(:skip_header_rows, 0)
      @skip_footer_rows = opts.fetch(:skip_footer_rows, 0)
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def parse(data)
      validate_headers
      data.force_encoding(encoding) if encoding
      data = StringIO.new(data) unless data.is_a? StringIO
      skip_header_rows.times { data.readline }
      records = data.each_with_object([]) do |row, a|
        a << parse_row(row) unless row.strip.empty?
      end
      skip_footer_rows.times { records.pop }
      records
    end

    def row_format
      @row_format ||= (?A << column_widths.join(?A)).freeze
    end

    private

    def column_widths
      @column_widths ||= case headers
      when Hash then headers.values
      when Array then headers
      end
    end

    def column_keys
      @column_keys ||= case headers
      when Hash then headers.keys.map(&:freeze)
      when Array then (0 ... headers.length).to_a
      end
    end

    def parse_row(row)
      Hash[column_keys.zip(row.unpack(row_format))]
    end

    def validate_headers
      @column_widths, @column_keys, @row_format = nil, nil, nil
      case headers
      when Hash, Array then true
      else raise ArgumentError, "Invalid headers set for #{self.class}, " \
                                "got #{headers.class}, expected Hash or Array"
      end
    end

  end
end
