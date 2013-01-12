require 'stockboy/reader'
require 'tempfile'
require 'roo'
# roo breaks without iconv loaded in some environments
require 'iconv' if RUBY_PLATFORM.downcase =~ /darwin|solaris|mswin32/

module Stockboy::Readers
  class Spreadsheet

    class << self
      def tmp_dir
        @tmp_dir ||= Stockboy.configuration.tmp_dir
      end
      attr_reader :tmp_dir
    end

    OPTIONS = [:format, :sheet]
    OPTIONS.each { |opt| attr_accessor opt }

    class DSL
      def initialize(instance)
        @instance = instance
      end

      def format(value)
        @instance.format = value
      end

      def sheet(value)
        @instance.sheet = value
      end
    end

    def initialize(opts={}, &block)
      @format = opts[:format] || :xls
      @sheet  = opts[:sheet]  || :first

      if block_given?
        DSL.new(self).instance_eval(&block)
      end
    end

    def parse(content)
      with_spreadsheet(content) do |table|
        headers = table.row(table.first_row).map(&:to_sym)

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
      Tempfile.open(['stockboy', ".#{@format}"]) do |file|
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

  end
end
