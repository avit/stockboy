require 'stockboy/provider'
require 'savon'

module Stockboy::Providers
  class SOAP < Stockboy::Provider
    # Local file path or remote URL of the WSDL for the SOAP provider.
    attr_accessor :wsdl_document

    # Yields an XML builder if passed a block for the SOAP body.
    # attr_accessor :body

    # Yields an XML builder if passed a block for the SOAP header.
    # attr_accessor :header

    def initialize(params={}, &block)
      super params, &block
      instance_eval(&block) if block_given?
    end

    def wsdl_document(*arg)
      client.wsdl.document = arg.first unless arg.empty?
      client.wsdl.document
    end
    alias_method :wsdl_document=, :wsdl_document

    def wsdl_namespace(*arg)
      client.wsdl.namespace = arg.first unless arg.empty?
      client.wsdl.namespace rescue nil
    end
    alias_method :wsdl_namespace=, :wsdl_namespace

    def endpoint(*arg)
      client.wsdl.endpoint = arg.first unless arg.empty?
      client.wsdl.endpoint rescue nil
    end
    alias_method :endpoint=, :endpoint

    # Parameter for the request SOAP Action (RPC)
    # Can take an underscored symbol which translates to the CamelCase XML
    # element representing the action.
    # If two symbol parameters are passed, the first represents the XML
    # namespace of the action. Can also accept a hash of options as the last
    # parameter, which are rendered as XML attributes on the action element.
    #
    def request(*args)
      args = args.first if args.first.is_a?(Array) && args.length == 1
      @request = args unless args.empty?
      @request
    end
    alias_method :request=, :request

    def header(*arg, &block)
      if block_given?
        @header = block
      else
        @header = arg.first unless arg.empty?
      end
      @header
    end
    alias_method :header=, :header

    def body(*arg, &block)
      if block_given?
        @body = block
      else
        @body = arg.first unless arg.empty?
      end
      @body
    end
    alias_method :body=, :body

    def client
      @client ||= Savon::Client.new
    end

    private

    def validate
      errors.add_on_blank(:endpoint) unless wsdl_document
      errors.blank?
    end

    def fetch_data
      @data = client.request(*@request) do |soap|
        soap.header &@header
        soap.body   &@body
      end
    end
  end
end
