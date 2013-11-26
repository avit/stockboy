require 'stockboy/reader'
require 'stockboy/string_pool'

module Stockboy::Readers

  # Extract data from XML
  #
  # This works great with SOAP, probably not fully-featured yet for various XML
  # formats.  The SOAP provider returns a hash, because it takes care of
  # extracting the envelope body already, so this reader supports options for
  # reading elements from a nested hash too.
  #
  # Backed by the Nori gem from Savon, see nori for full options.
  #
  class XML < Stockboy::Reader
    include Stockboy::StringPool

    # Override source encoding
    #
    # @!attribute [rw] encoding
    # @return [String]
    #
    dsl_attr :encoding

    # Element nesting to traverse, the last one should represent the record
    # instances that contain tags for each attribute.
    #
    # @!attribute [rw] elements
    # @return [Array]
    # @example
    #   elements ["allItemsResponse", "itemList", "recordItem"]
    #
    dsl_attr :elements, attr_accessor: false

    # Removes namespace prefixes from tag names, default true.
    #
    # @!attribute [rw] strip_namespaces
    # @return [Boolean]
    #
    dsl_attr :strip_namespaces, attr_accessor: false

    # Change tag formatting, e.g. underscore if it happens to match your actual
    # record attributes
    #
    # @!attribute [rw] convert_tags_to
    # @return [Proc]
    # @example
    #   convert_tags_to ->(tag) { tag.underscore }
    #
    dsl_attr :convert_tags_to, attr_accessor: false

    # Detects input tag types and tries to extract dates, times, etc. from the data.
    # Normally this is handled by the attribute map.
    #
    # @!attribute [rw] advanced_typecasting
    # @return [Boolean]
    #
    dsl_attr :advanced_typecasting, attr_accessor: false

    # Defaults to Nokogiri. Why would you change it?
    #
    # @!attribute [rw] parser
    # @return [Symbol]
    #
    dsl_attr :parser, attr_accessor: false

    [:strip_namespaces, :convert_tags_to, :advanced_typecasting, :parser].each do |opt|
      define_method(opt)        { @xml_options[opt] }
      define_method(:"#{opt}=") { |value| @xml_options[opt] = value }
    end

    def elements
      convert_tags_to ? @elements.map(&convert_tags_to) : @elements
    end

    def elements=(schema)
      return @elements = [] unless schema
      raise(ArgumentError, "expected an array of XML tag strings") unless schema.is_a? Array
      @elements = schema.map(&:to_s)
    end

    # @!endgroup

    # Initialize a new XML reader
    #
    def initialize(opts={}, &block)
      super
      self.elements = opts.delete(:elements)
      @xml_options = opts
      DSL.new(self).instance_eval(&block) if block_given?
    end

    # XML options passed to the underlying Nori instance
    #
    # @!attribute [r] options
    # @return [Hash]
    #
    def options
      @xml_options
    end

    def parse(data)
      hash = if data.is_a? Hash
        data
      else
        if data.respond_to? :to_xml
          data.to_xml("UTF-8")
          nori.parse(data)
        elsif data.respond_to? :to_hash
          data.to_hash
        else
          data.encode!("UTF-8", encoding) if encoding
          nori.parse(data)
        end
      end

      with_string_pool do
        remap_keys hash
        extract hash
      end
    end

    private

    def nori
      @nori ||= Nori.new(options)
    end

    def extract(hash)
      result = elements.inject hash do |memo, key|
        return [] if memo[key].nil?
        memo[key]
      end

      result = [result] unless result.is_a? Array
      result.compact!
      result
    end

    def remap_keys(node)
      mapper = convert_tags_to || ->(tag) { tag }
      case node
      when Hash
        node.keys.each do |k|
          tag = string_pool(mapper.call(k))
          node[tag] = remap_keys(node.delete(k))
        end
      when Array
        node.each { |value| remap_keys(value) }
      end
      node
    end

  end
end
