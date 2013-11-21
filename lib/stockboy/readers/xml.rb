require 'stockboy/reader'
require 'stockboy/string_pool'

module Stockboy::Readers
  class XML < Stockboy::Reader
    include Stockboy::StringPool

    XML_OPTIONS = [:strip_namespaces,
                   :convert_tags_to,
                   :advanced_typecasting,
                   :parser]
    XML_OPTIONS.each do |opt|
      define_method(opt)        { @xml_options[opt] }
      define_method(:"#{opt}=") { |value| @xml_options[opt] = value }
    end

    OPTIONS = [:elements]
    attr_accessor *OPTIONS

    class DSL
      include Stockboy::DSL
      dsl_attrs :encoding
      dsl_attrs *XML_OPTIONS
      dsl_attrs *OPTIONS
    end

    def initialize(opts={}, &block)
      super
      self.elements = opts.delete(:elements)
      @xml_options = opts
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def options
      @xml_options
    end

    def elements=(schema)
      return @elements = [] unless schema
      raise(ArgumentError, "expected an array of XML tag strings") unless schema.is_a? Array
      @elements = schema.map(&:to_s)
    end

    def elements
      convert_tags_to ? @elements.map(&convert_tags_to) : @elements
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
