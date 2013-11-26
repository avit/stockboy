require 'stockboy/provider'
require 'httpi'

module Stockboy::Providers

  # Fetches data from an HTTP endpoint
  #
  # == Job template DSL
  #
  #   provider :http do
  #     get "http://example.com/api/things"
  #   end
  #
  class HTTP < Stockboy::Provider

    # @!group Options

    # Shorthand for +:method+ and +:uri+ using HTTP GET
    #
    # @!attribute [rw] get
    # @return [String]
    # @example
    #   get 'http://example.com/api/things'
    #
    dsl_attr :get, attr_writer: false

    # Shorthand for +:method+ and +:uri+ using HTTP POST
    #
    # @!attribute [rw] post
    # @return [String]
    # @example
    #   post 'http://example.com/api/search'
    #
    dsl_attr :post, attr_writer: false

    # HTTP method: +:get+ or +:post+
    #
    # @!attribute [rw] method
    # @return [Symbol]
    # @example
    #   method :post
    #
    dsl_attr :method, attr_writer: false

    # HTTP host and path to the data resource
    #
    # @!attribute [rw] uri
    # @return [String]
    # @example
    #   uri 'http://example.com/api/things'
    #
    dsl_attr :uri, attr_accessor: false, alias: :url

    # Hash of query options
    #
    # @!attribute [rw] query
    # @return [Hash]
    # @example
    #   query start: 1, limit: 100
    #
    dsl_attr :query

    def method=(http_method)
      @method = http_method.downcase.to_sym
    end

    def uri
      URI(@uri).tap { |u| u.query = URI.encode_www_form(@query) }
    end

    def uri=(uri)
      @uri = uri
    end

    def get=(uri)
      @method = :get
      @uri = uri
    end

    def post=(uri)
      @method = :post
      @uri = uri
    end

    # @!endgroup

    # Initialize an HTTP provider
    #
    def initialize(opts={}, &block)
      super(opts, &block)
      self.uri    = opts[:uri]
      self.method = opts[:method] || :get
      self.query  = opts[:query]  || Hash.new
      DSL.new(self).instance_eval(&block) if block_given?
    end

    private

    def validate
      errors.add_on_blank [:uri, :method]
      errors.empty?
    end

    def fetch_data
      request = HTTPI::Request.new
      request.url = uri
      response = HTTPI.send(method, request)
      if response.error?
        errors.add :response, "HTTP respone error: #{response.code}"
      else
        @data = response.body
      end
    end

  end
end
