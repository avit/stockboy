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
    dsl_attr :post, attr_accessor: false

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
      return nil if @uri.nil? || @uri.to_s.empty?
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

    def post_body
      return nil unless post?
      @post_body
    end

    def post_body=(post_body)
      @post_body = post_body
    end

    # POST body for setting directly on a request
    #
    # @!attribute [rw] post_body
    # @return [String]
    # @example
    #   post_body '<somexml>'
    #
    dsl_attr :post_body, attr_accessor: false, alias: :body

    def method=(http_method)
      return @method = nil unless %w(get post).include? http_method.to_s.downcase
      @method = http_method.to_s.downcase.to_sym
    end

    def get=(uri)
      @method = :get
      @uri = uri
    end

    def post=(*attrs)
      attrs = Array(attrs).flatten
      options = attrs.last.is_a?(Hash) ? attrs.pop : {} # extract_options
      @method = :post
      @uri = attrs.first
      @post_body = options[:body]
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
      req.body = post_body if post_body
      req.auth.basic(username, password) if username && password
      block_given? ? yield(req) : req
    ensure
      HTTPI.logger = orig_logger
    end

    private

    def validate
      errors << "uri must be specified" unless uri
      errors << "method (:get, :post) must be specified" unless method
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

    def post?
      method == :post
    end
  end
end
