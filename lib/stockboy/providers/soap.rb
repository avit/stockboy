require 'stockboy/provider'
require 'savon'

module Stockboy::Providers
  class SOAP < Stockboy::Provider

    dsl_attrs :wsdl,
              :request,
              :namespace,
              :namespace_id,
              :endpoint,
              :message,
              :headers

    def initialize(params={}, &block)
      super params, &block
      instance_eval(&block) if block_given?
    end

    def client
      @client ||= Savon.client(client_options)
    end

    private

    def client_options
      opts = if wsdl
        {wsdl: wsdl}
      elsif endpoint
        {endpoint: endpoint}
      end
      opts[:namespace] = namespace if namespace
      opts[:namespace_identifier] = namespace_id if namespace_id
      opts[:headers] = headers if headers
      opts
    end

    def validate
      errors.add_on_blank(:endpoint) unless wsdl
      errors.blank?
    end

    def fetch_data
      @data = client.call(@request, message: message).body
    end
  end
end
