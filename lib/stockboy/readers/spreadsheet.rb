require 'stockboy/reader'
require 'tempfile'
require 'roo'
require 'roo-xls'

module Stockboy::Readers

  # Parse an Excel spreadsheet
  #
  # Backed by Roo gem. See roo for other configuration options.
  #
  class Spreadsheet < Stockboy::Reader

    # Spreadsheet format
    #
    # @!attribute [rw] format
    # @return [Symbol] +:xls+ or +:xslx+
    #
    dsl_attr :format

    # Spreadsheet sheet number, defaults to first
    #
    # @!attribute [rw] sheet
    # @return [Fixnum]
    #
    dsl_attr :sheet

    # Line number to look for headers, starts counting at 1, like in Excel
    #
    # When specified without +first_row+, then the next row becomes the first
    # data row by default.
    #
    # @!attribute [rw] header_row
    # @return [Fixnum]
    #
    dsl_attr :header_row

    # Line number of first data row, starts counting at 1, like in Excel
    #
    # @!attribute [rw] first_row
    # @return [Fixnum]
    #
    dsl_attr :first_row

    # Line number of last data row, use negative numbers to count back from end
    #
    # @!attribute [rw] last_row
    # @return [Fixnum]
    #
    dsl_attr :last_row

    # Override to set headers manually
    #
    # When specified, the first spreadsheet row is the default
    # first data row, unless specified by +first_row+.
    #
    # @!attribute [rw] headers
    # @return [Array]
    #
    dsl_attr :headers

    # Options passed to underlying Roo library
    #
    # @!attribute [rw] options
    # @return [Hash]
    #
    dsl_attr :options

    # @!endgroup

    # Initialize a new Spreadsheet reader
    #
    # @param [Hash] opts
    #
    def initialize(opts={}, &block)
      super
      @format = opts[:format] || :xls
      @sheet  = opts[:sheet]  || :first
      @first_row = opts[:first_row]
      @last_row  = opts[:last_row]
      @header_row  = opts[:header_row]
      @headers = opts[:headers]
      @options = opts[:options] || {}
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def parse(content)
      with_spreadsheet_tempfile(content) do |table|
        headers = table_headers(table)

        enum_data_rows(table).inject([]) do |rows, i|
          rows << Hash[headers.zip(table.row(i))]
        end
      end
    end

    private

    def enum_data_rows(table)
      first_table_row(table).upto last_table_row(table)
    end

    def with_spreadsheet_tempfile(content)
      Tempfile.open(tmp_name, Stockboy.configuration.tmp_dir) do |file|
        file.binmode
        file.write content
        file.fsync
        table = Roo::Spreadsheet.open(file.path, @options)
        table.default_sheet = sheet_number(table, @sheet)
        table.header_line = @header_row if @header_row
        yield table
      end
    end

    def sheet_number(table, id)
      case id
      when Symbol then table.sheets.public_send id
      when Fixnum then table.sheets[id-1]
      when String then id
      end
    end

    def first_table_row(table)
      return @first_row if @first_row

      if @headers
        table.first_row
      elsif @header_row
        @header_row + 1
      else
        table.first_row + 1
      end
    end

    def last_table_row(table)
      if @last_row.to_i < 0
        table.last_row + @last_row + 1
      elsif @last_row.to_i > 0
        @last_row
      else
        table.last_row
      end
    end

    def table_headers(table)
      return @headers if @headers
      table.row(table_header_row(table)).map { |h| h.to_s unless h.nil? }
    end

    def table_header_row(table)
      [table.header_line, table.first_row].max
    end

    def tmp_name
      ['stockboy', ".#{@format}"]
    end
  end
end
