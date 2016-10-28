require 'stockboy/configuration'
require 'stockboy/reader'
require 'csv'

module Stockboy::Readers

  # Parse data from CSV into hashes
  #
  # All standard ::CSV options are respected and passed through
  #
  # @see
  #   http://www.ruby-doc.org/stdlib-2.0.0/libdoc/csv/rdoc/CSV.html#DEFAULT_OPTIONS
  #
  class CSV < Stockboy::Reader

    # @!group Options

    # Override source file encoding
    #
    # @!attribute [rw] encoding
    # @return [String]
    #
    dsl_attr :encoding

    # Skip number of rows at start of file before data starts
    #
    # @!attribute [rw] skip_header_rows
    # @return [Fixnum]
    #
    dsl_attr :skip_header_rows

    # Skip number of rows at end of file after data ends
    #
    # @!attribute [rw] skip_footer_rows
    # @return [Fixnum]
    #
    dsl_attr :skip_footer_rows

    # @!attribute [rw] col_sep
    #   @macro dsl_attr
    #   @return [String]
    #
    # @!attribute [rw] row_sep
    #   @macro dsl_attr
    #   @return [String]
    #
    # @!attribute [rw] quote_char
    #   @macro dsl_attr
    #   @return [String]
    #
    # @!attribute [rw] headers
    #   @macro dsl_attr
    #   @return [Array, String]
    #
    ::CSV::DEFAULT_OPTIONS.keys.each do |opt|
      dsl_attr opt, attr_accessor: false
      define_method(opt)        { @csv_options[opt] }
      define_method(:"#{opt}=") { |value| @csv_options[opt] = value }
    end

    # @!endgroup

    # Initialize a new CSV reader
    #
    # All stdlib ::CSV options are respected.
    # @see http://ruby-doc.org/stdlib-2.0.0/libdoc/csv/rdoc/CSV.html#method-c-new
    #
    # @param [Hash] opts
    #
    def initialize(opts={}, &block)
      super
      @csv_options = opts.reject {|k,v| !::CSV::DEFAULT_OPTIONS.keys.include?(k) }
      @csv_options[:headers] = @csv_options.fetch(:headers, true)
      @skip_header_rows = opts.fetch(:skip_header_rows, 0)
      @skip_footer_rows = opts.fetch(:skip_footer_rows, 0)
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def parse(data)
      chain = options[:header_converters] || []
      chain << proc{ |h| h.freeze }
      opts = options.merge(header_converters: chain)
      ::CSV.parse(sanitize(data), opts).map(&:to_hash)
    end

    # Hash of all CSV-specific options
    #
    # @!attribute [r] options
    #   @return [Hash]
    #
    def options
      @csv_options
    end

    private

    # Clean incoming data based on set encoding or best information
    #
    #  1. Assign the given input encoding setting if available
    #  2. Scrub invalid characters for the encoding. (Scrubbing does not apply
    #     for BINARY input, which is undefined.)
    #  3. Encode to UTF-8 with considerations for undefined input. The main
    #     issue are control characters that are absent in UTF-8 (and ISO-8859-1)
    #     but are common printable characters in Windows-1252, so we preserve
    #     this range as a best guess.
    #  4. Delete null bytes that are inserted as terminators by some "CSV" output
    #  5. Delete leading/trailing garbage lines based on settings
    #
    def sanitize(data)
      data = data.dup
      data.force_encoding encoding if encoding
      data.scrub!
      data.encode! Encoding::UTF_8, universal_newline: true, fallback: proc { |c|
        c.force_encoding(Encoding::Windows_1252) if (127..159).cover? c.ord
      }
      data.delete! 0.chr
      data.chomp!
      from = row_start_index(data, skip_header_rows)
      to = row_end_index(data, skip_footer_rows)
      data[from..to]
    end

    def row_start_index(data, skip_rows)
      Array.new(skip_rows).inject(0) { |i| data.index(/$/, i) + 1 }
    end

    def row_end_index(data, skip_rows)
      Array.new(skip_rows).inject(-1) { |i| data.rindex(/$/, i) - 1 }
    end
  end
end
