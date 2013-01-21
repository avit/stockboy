require 'stockboy/reader'

module Stockboy::Readers
  class XML < Stockboy::Reader

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
      @elements    = opts.delete(:elements)
      @xml_options = opts
      DSL.new(self).instance_eval(&block) if block_given?
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
