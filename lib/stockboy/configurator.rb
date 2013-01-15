require 'stockboy/job'
require 'stockboy/providers'
require 'stockboy/readers'
require 'stockboy/attribute_map'

module Stockboy
  class Configurator

    attr_reader :params

    def initialize(dsl='', file=__FILE__, &block)
      @params = {}
      @params[:filters] = {}
      if block_given?
        instance_eval(&block)
      else
        instance_eval(dsl, file)
      end
      self
    end

    def provider(provider_class, opts={}, &block)
      raise ArgumentError unless provider_class

      @params[:provider] = case provider_class
      when Symbol
        Providers.find(provider_class).new(opts, &block)
      when Class
        provider_class.new(opts, &block)
      else
        provider_class
      end
    end
    alias_method :connection, :provider

    def reader(reader_class, opts={}, &block)
      raise ArgumentError unless reader_class

      @params[:reader] = case reader_class
      when Symbol
        Readers.find(reader_class).new(opts, &block)
      when Class
        reader_class.new(opts, &block)
      else
        reader_class
      end
    end
    alias_method :format, :reader

    def attributes(&block)
      raise ArgumentError unless block_given?

      @params[:attributes] = AttributeMap.new(&block)
    end

    def filter(key, callable=nil, &block)
      raise ArgumentError unless key
      raise ArgumentError unless callable.respond_to?(:call) ^ block_given?

      @params[:filters][key] = block || callable
    end

    def to_job
      Job.new(@params)
    end

  end
end
