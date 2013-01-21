require 'stockboy/reader'
require 'tempfile'
require 'roo'
# roo breaks without iconv loaded in some environments
require 'iconv' if RUBY_PLATFORM.downcase =~ /darwin|solaris|mswin32/

module Stockboy::Readers
  class Spreadsheet < Stockboy::Reader

    OPTIONS = [:format, :sheet]
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
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def parse(content)
      with_spreadsheet(content) do |table|
        headers = table.row(table.first_row).map { |h| h.to_sym unless h.nil? }

        enum_data_rows(table).inject([]) do |rows, i|
          rows << Hash[headers.zip(table.row(i))]
        end
      end
    end

    private

    def enum_data_rows(table)
      (table.first_row + 1).upto table.last_row
    end

    def with_spreadsheet(content)
      Tempfile.open(tmp_name, encoding: content.encoding) do |file|
        file.write content
        table = Roo::Spreadsheet.open(file.path)
        table.default_sheet = sheet_number(table, @sheet)
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

    def tmp_name
      ['stockboy', ".#{@format}"]
    end
  end
end
