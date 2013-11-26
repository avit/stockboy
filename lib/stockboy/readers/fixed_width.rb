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
    # @return [Array<Fixnum>, Hash{Object=>Fixnum}]
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
    # overridden
    #
    # @return [String]
    #
    dsl_attr :skip_header_rows

    # Number of file rows to skip from start of file
    #
    # Useful if the file starts with a preamble or header metadata
    #
    # @return [Fixnum]
    #
    dsl_attr :skip_footer_rows

    # Number of file rows to skip at end of file
    #
    # Useful if the file ends with a summary or notice
    #
    # @return [Fixnum]
    #
    dsl_attr :row_format

    # Override original file encoding
    #
    # @return [String]
    #
    dsl_attr :encoding

    # @!endgroup

    # Initialize a new fixed-width reader
    #
    # @param [Hash] opts
    # @option opts [Array<Fixnum>, Hash<Fixnum>] headers
    # @option opts [Fixnum] skip_header_rows
    # @option opts [Fixnum] skip_footer_rows
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
      @column_widths, @column_keys = nil, nil
      data.force_encoding!(encoding) if encoding
      data = StringIO.new(data) unless data.is_a? StringIO
      skip_header_rows.times { data.readline }
      records = data.reduce([]) do |a, row|
        a.tap { a << parse_row(row) unless row.strip.empty? }
      end
      skip_footer_rows.times { records.pop }
      records
    end

    def row_format
      @row_format ||= (?A << column_widths.join(?A)).freeze
    end

    private

    def column_widths
      return @column_widths if @column_widths
      @column_widths = case headers
      when Hash then headers.values
      when Array then headers
      else
        raise "Invalid headers set for #{self.class}"
      end
    end

    def column_keys
      return @column_keys if @column_keys
      @column_keys = case headers
      when Hash then headers.keys.map(&:freeze)
      when Array then (0 ... headers.length).to_a
      else
        raise "Invalid headers set for #{self.class}"
      end
    end

    def parse_row(row)
      Hash[column_keys.zip(row.unpack(row_format))]
    end

  end
end
