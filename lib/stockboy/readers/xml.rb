require 'stockboy/reader'

module Stockboy::Readers
  class XML < Stockboy::Reader
    XML_OPTION_KEYS = [:strip_namespaces,
                       :convert_tags_to,
                       :advanced_typecasting,
                       :parser]

    XML_OPTION_KEYS.each do |attr, opt|
      define_method attr do |*arg|
        options[attr.to_sym] = arg.first unless arg.empty?
        options[attr.to_sym]
      end
    end

    dsl_attrs :elements

    def initialize(opts={}, &block)
      @elements = opts.delete(:elements)
      @xml_options = opts
      instance_eval &block if block_given?
    end

    def options
      @xml_options
    end

    def parse(data)
      if data.is_a? Hash
        hash = data
      else
        hash = if data.respond_to? :to_xml
          Nori.new(@xml_options).parse(data.to_xml)
        elsif data.respond_to? :to_hash
          data.to_hash
        else
          Nori.new(@xml_options).parse(data)
        end
      end

      return extract hash
    end

    private

    def extract(hash)
      result = Array(@elements).inject hash do |memo, key|
        return [] if memo[key].nil?
        memo[key]
      end

      Array(result).compact
    end

  end
end
