require 'stockboy/provider'
require 'stockboy/string_pool'
require 'savon'

module Stockboy::Providers

  # Fetch data from a SOAP endpoint
  #
  # Backed by Savon gem, see savon for full configuration options: extra
  # options are passed through.
  #
  class SOAP < Stockboy::Provider
    include Stockboy::StringPool

    # @!group Options
    #
    # These options correspond to Savon client options

    # URL with the WSDL document
    #
    # @!attribute [rw] wsdl
    # @return [String]
    # @example
    #   wsdl "http://example.com/api/soap?wsdl"
    #
    dsl_attr :wsdl

    # The name of the request, see your SOAP documentation
    #
    # @!attribute [rw] request
    # @return [String]
    # @example
    #   request "allItemsDetails"
    #
    dsl_attr :request

    # @return [String]
    # @!attribute [rw] namespace
    #   Optional if specified in WSDL
    #
    dsl_attr :namespace

    # @return [String]
    # @!attribute [rw] namespace_id
    #   Optional if specified in WSDL
    #
    dsl_attr :namespace_id

    # @return [String]
    # @!attribute [rw] endpoint
    #   Optional if specified in WSDL
    #
    dsl_attr :endpoint

    # Hash of message options passed in the request, often includes
    # credentials and query options.
    #
    # @!attribute [rw] message
    # @return [Hash]
    # @example
    #   message "clientId" => "12345", "updatedSince" => "2012-12-12"
    #
    dsl_attr :message

    # Hash of optional HTTP request headers
    #
    # @!attribute [rw] headers
    # @return [Hash]
    # @example
    #   headers "X-ClientKey" => "12345"
    #
    dsl_attr :headers

    # @!endgroup

    # Initialize a new SOAP provider
    #
    def initialize(opts={}, &block)
      super
      DSL.new(self).instance_eval(&block) if block_given?
    end

    # Connection object to the configured SOAP endpoint
    #
    # @return [Savon::Client]
    #
    def client
      @client ||= Savon.client(client_options)
      return @client unless block_given?
      yield @client
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
