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
      @params[:attributes] = AttributeMap.new(&block)
    end

    def filter(key, callable=nil, &block)
      if block_given?
        @params[:filters][key] = block
      else
        if callable.respond_to?(:call)
          @params[:filters][key] = callable
        end
      end
    end

    def to_job
      Job.new(@params)
    end

  end
end
