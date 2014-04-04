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

    # User name for basic auth connection credentials
    #
    # @!attribute [rw] username
    # @return [String]
    # @example
    #   username "arthur"
    #
    dsl_attr :username

    # Password for basic auth connection credentials
    #
    # @!attribute [rw] password
    # @return [String]
    # @example
    #   password "424242"
    #
    dsl_attr :password

    def uri
      return nil if @uri.nil? || @uri.empty?
      URI(@uri).tap { |u| u.query = URI.encode_www_form(@query) if @query }
    end

    def uri=(uri)
      @uri = uri
    end

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
      return @method = nil unless %w(get post).include? http_method.to_s.downcase
      @method = http_method.to_s.downcase.to_sym
    end

    def get=(uri)
      @method = :get
      @uri = uri
    end

    def post=(uri)
      @method = :post
      @uri = uri
    end

    def username=(username)
      @username = username
    end

    def password=(password)
      @password = password
    end

    # @!endgroup

    # Initialize an HTTP provider
    #
    def initialize(opts={}, &block)
      super(opts, &block)
      self.uri      = opts[:uri]
      self.method   = opts[:method] || :get
      self.query    = opts[:query]  || Hash.new
      self.username = opts[:username]
      self.password = opts[:password]
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def client
      orig_logger, HTTPI.logger = HTTPI.logger, logger
      req = HTTPI::Request.new.tap { |c| c.url = uri }
      req.auth.basic(username, password) if username && password
      yield req if block_given?
      HTTPI.logger = orig_logger
      req
    end

    private

    def validate
      errors << "uri must be specified" if uri.blank?
      errors << "method (:get, :post) must be specified" if method.blank?
      errors.empty?
    end

    def fetch_data
      client do |request|
        response = HTTPI.request(method, request)
        if response.error?
          errors << "HTTP response error: #{response.code}"
        else
          @data = response.body
        end
      end
    end

  end
end
