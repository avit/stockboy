require 'stockboy/provider'
require 'stockboy/string_pool'
require 'savon'

module Stockboy::Providers
  class SOAP < Stockboy::Provider
    include Stockboy::StringPool

    OPTIONS = [:wsdl,
               :request,
               :namespace,
               :namespace_id,
               :endpoint,
               :message,
               :headers]
    attr_accessor *OPTIONS

    class DSL
      include Stockboy::DSL
      dsl_attrs *OPTIONS
    end

    def initialize(opts={}, &block)
      super
      DSL.new(self).instance_eval(&block) if block_given?
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
      opts[:convert_response_tags_to] = ->(tag) { string_pool(tag) }
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
      with_string_pool do
        @data = client.call(@request, message: message).body
      end
    end

  end
end
