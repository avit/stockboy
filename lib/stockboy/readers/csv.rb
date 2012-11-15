require 'stockboy/reader'
require 'stockboy/candidate_record'
require 'csv'

module Stockboy::Readers
  class CSV < Stockboy::Reader

    dsl_attrs :skip_header_rows

    ::CSV::DEFAULT_OPTIONS.keys.each do |attr, opt|
      define_method attr do |*arg|
        options[attr.to_sym] = arg.first unless arg.empty?
        options[attr.to_sym]
      end
    end

    def initialize(opts={}, &block)
      super
      @csv_options = opts.reject {|k,v| !::CSV::DEFAULT_OPTIONS.keys.include?(k) }
      @csv_options[:headers] = @csv_options.fetch(:headers, true)
      @skip_header_rows = 0
      instance_eval(&block) if block_given?
    end

    def parse(data)
      records = ::CSV.parse(sanitize(data), options).map &:to_hash
    end

    def options
      @csv_options
    end

    private

    def sanitize(data)
      data.force_encoding(encoding) if encoding
      data.sub(/(.*\n){#@skip_header_rows}/, '')
    end

  end
end
