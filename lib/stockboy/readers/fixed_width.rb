require 'stockboy/reader'

module Stockboy::Readers

  # For reading fixed-width data split by column widths
  #
  # @example
  #   # return columns as numeric indexes
  #   reader.headers = [10, 5, 10, 42]
  #   # return columns as named indexes
  #   reader.headers = {name: 10, age: 5, planet: 10, notes: 42}
  #
  class FixedWidth < Stockboy::Reader

    OPTIONS = [
      :skip_header_rows,
      :skip_footer_rows,
      :headers,
      :row_format
    ]
    attr_accessor *OPTIONS

    class DSL
      include Stockboy::DSL
      dsl_attrs :encoding
      dsl_attrs *OPTIONS
    end

    def initialize(opts={}, &block)
      super
      @headers          = opts[:headers]
      @skip_header_rows = opts.fetch(:skip_header_rows, 0)
      @skip_footer_rows = opts.fetch(:skip_footer_rows, 0)
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def parse(data)
      data = StringIO.new(data) unless data.is_a? StringIO
      skip_header_rows.times { data.readline }
      records = data.reduce([]) do |a, row|
        a.tap { a << parse_row(row) unless row.strip.empty? }
      end
      skip_footer_rows.times { records.pop }
      records
    end

    private

    def column_widths
      case headers
      when Hash then headers.values
      when Array then headers
      else
        raise "Invalid headers set for #{self.class}"
      end
    end

    def column_keys
      case headers
      when Hash then headers.keys
      when Array then (0 ... headers.length).to_a
      else
        raise "Invalid headers set for #{self.class}"
      end
    end

    def parse_row(row)
      Hash[column_keys.zip(row.unpack(row_format))]
    end

    def row_format
      @row_format || ?A << column_widths.join(?A)
    end
  end
end
