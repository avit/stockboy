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

    # Maximum time to establish a connection
    #
    # @!attribute [rw] open_timeout
    # @return [Integer]
    # @example
    #   open_timeout 10
    #
    dsl_attr :open_timeout

    # Maximum time to read data from connection
    #
    # @!attribute [rw] read_timeout
    # @return [Integer]
    # @example
    #   read_timeout 10
    #
    dsl_attr :read_timeout

    # The name of the request, see your SOAP documentation
    #
    # @!attribute [rw] request
    # @return [String]
    # @example
    #   request "allItemsDetails"
    #
    dsl_attr :request

    # @return [Symbol]
    # @example
    #   env_namespace :soapenv
    #
    dsl_attr :env_namespace

    # @return [String]
    # @!attribute [rw] namespace
    #   Optional if specified in WSDL
    #
    dsl_attr :namespace

    # @return [Hash]
    # @!attribute [rw] namespaces
    #   Optional if specified in WSDL
    #
    dsl_attr :namespaces

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

    # Message tag name
    #
    # @!attribute [rw] message_tag
    # @return [String]
    # @example
    #   message_tag "GetResult"
    #
    dsl_attr :message_tag

    # @return [String]
    # @example
    #   soap_action "urn:processMessage"
    #
    dsl_attr :soap_action

    # XML string to override the Soap headers
    #
    # @!attribute [rw] soap_header
    # @return [String]
    # @example
    #   soap_header "<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">..."
    #
    dsl_attr :soap_header

    # @return [Hash]
    # @example
    #   attributes {}
    #
    dsl_attr :attributes

    # Change the default response type, default :hash
    #
    # @!attribute [rw] response_format
    # @return [Symbol]
    # @example
    #   response_format :xml
    #
    dsl_attr :response_format

    # Hash of optional HTTP request headers
    #
    # @!attribute [rw] headers
    # @return [Hash]
    # @example
    #   headers "X-ClientKey" => "12345"
    #
    dsl_attr :headers

    # Array of WSSE Auth values
    #
    # @!attribute [rw] wsse_auth
    # @return [Array]
    # @example
    #   wsse_auth ["Username", "Password"]
    #
    dsl_attr :wsse_auth

    # @!endgroup

    # Initialize a new SOAP provider
    #
    def initialize(opts={}, &block)
      super
      @response_format = opts[:response_format] || :hash
      DSL.new(self).instance_eval(&block) if block_given?
    end

    # Connection object to the configured SOAP endpoint
    #
    # @return [Savon::Client]
    #
    def client
      @client ||= Savon.client(client_options)
      @client.globals.open_timeout(open_timeout) if open_timeout
      @client.globals.read_timeout(read_timeout) if read_timeout
      yield @client if block_given?
      @client
    end

    private

    def client_options
      opts = if wsdl
        {wsdl: wsdl}
      elsif endpoint
        {endpoint: endpoint}
      end
      opts[:open_timeout] = open_timeout if open_timeout
      opts[:read_timeout] = read_timeout if read_timeout
      opts[:logger] = logger
      opts[:log] = logger.debug?
      opts[:convert_response_tags_to] = ->(tag) { string_pool(tag) }
      opts[:namespace] = namespace if namespace
      opts[:namespaces] = namespaces if namespaces
      opts[:namespace_identifier] = namespace_id if namespace_id
      opts[:env_namespace] = env_namespace if env_namespace
      opts[:headers] = headers if headers
      opts[:wsse_auth] = wsse_auth if wsse_auth
      opts
    end

    def validate
      errors << "endpoint or wsdl must be specified" if endpoint.blank? unless wsdl
      errors.blank?
    end

    def fetch_data
      with_string_pool do
        response = client.call(
          @request,
          message:         message,
          message_tag:     message_tag,
          soap_action:     soap_action,
          soap_header:     soap_header,
          attributes:      attributes
        )
        @data = case response_format
        when :xml
          response.xml
        else
          response.body
        end
      end
    end
  end
end
