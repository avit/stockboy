require 'stockboy/provider'
require 'httpi'

module Stockboy::Providers
  class HTTP < Stockboy::Provider

    OPTIONS = [:uri, :method, :query]
    attr_accessor *OPTIONS

    class DSL
      include Stockboy::DSL
      dsl_attrs :get, :post, *OPTIONS
      alias :url :uri
      alias :url= :uri=
    end

    def initialize(opts={}, &block)
      super(opts, &block)
      self.uri    = opts[:uri]
      self.method = opts[:method] || :get
      self.query  = opts[:query]  || Hash.new
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def method=(http_method)
      @method = http_method.downcase.to_sym
    end

    def uri
      URI(@uri).tap { |u| u.query = URI.encode_www_form(@query) }
    end
    alias :url :uri

    def uri=(uri)
      @uri = uri
    end
    alias :url= :uri=

    def get=(uri)
      method = :get
      @uri = uri
    end
    alias :get :get=

    def post=(uri)
      method = :post
      @uri = uri
    end
    alias :post :post=

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
