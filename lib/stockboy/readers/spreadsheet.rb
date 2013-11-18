require 'stockboy/reader'
require 'tempfile'
require 'roo'

module Stockboy::Readers
  class Spreadsheet < Stockboy::Reader

    OPTIONS = [:format, :sheet, :header_row, :first_row, :last_row, :headers, :roo_options]
    attr_accessor *OPTIONS

    class DSL
      include Stockboy::DSL
      dsl_attrs *OPTIONS
    end

    class << self
      def tmp_dir; @tmp_dir ||= Stockboy.configuration.tmp_dir end
      attr_writer :tmp_dir
    end

    def initialize(opts={}, &block)
      super
      @format = opts[:format] || :xls
      @sheet  = opts[:sheet]  || :first
      @first_row = opts[:first_row]
      @last_row  = opts[:last_row]
      @header_row  = opts[:header_row]
      @headers = opts[:headers]
      @roo_options = opts[:roo_options] || {}
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
      first_row(table).upto last_row(table)
    end

    def with_spreadsheet_tempfile(content)
      Tempfile.open(tmp_name) do |file|
        file.binmode
        file.write content
        table = Roo::Spreadsheet.open(file.path, @roo_options)
        table.default_sheet = sheet_number(table, @sheet)
        table.header_line = @header_line if @header_line
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

    def first_row(table)
      @first_row || table.first_row
    end

    def last_row(table)
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
