require 'spec_helper'
require 'stockboy/providers/http'

module Stockboy
  describe Providers::HTTP do
    subject(:provider) { Stockboy::Providers::HTTP.new }

    it "should assign parameters from :uri option" do
      provider.uri    = "http://www.example.com/"
      provider.query  = {user: 'u'}
      provider.method = :get

      expect(provider.uri).to    eq URI("http://www.example.com/?user=u")
      expect(provider.query).to  eq({user: 'u'})
      expect(provider.method).to eq :get
    end

    it "should assign parameters from :get" do
      provider.get    = "http://www.example.com/"
      provider.query  = {user: 'u'}

      expect(provider.uri).to    eq URI("http://www.example.com/?user=u")
      expect(provider.query).to  eq({user: 'u'})
      expect(provider.method).to eq :get
    end

    it "should assign parameters from :post" do
      provider.post   = "http://www.example.com/"
      provider.query  = {user: 'u'}

      expect(provider.uri).to    eq URI("http://www.example.com/?user=u")
      expect(provider.query).to  eq({user: 'u'})
      expect(provider.method).to eq :post
    end

    it "should assign parameters from :headers" do
      provider.headers = {"Content-Type" => "test/xml"}

      expect(provider.headers["Content-Type"]).to eq "test/xml"
    end

    it "should assign parameters from :body" do
      provider.body = "<somexml></somexml>"

      expect(provider.body).to eq "<somexml></somexml>"
    end

    it "should assign basic auth parameters" do
      provider.username = "username"
      provider.password = "password"

      expect(provider.username).to eq "username"
      expect(provider.password).to eq "password"
    end

    describe ".new" do
      its(:errors) { should be_empty }

      it "accepts block DSL initialization" do
        provider = Providers::HTTP.new do
          get    "http://www.example.com/"
          query  user: 'u'
        end

        expect(provider.uri).to    eq URI("http://www.example.com/?user=u")
        expect(provider.query).to  eq({ user: 'u' })
        expect(provider.method).to eq :get
      end
    end

    describe "validation" do
      it "should be valid with minimal GET params" do
        provider.uri = "http://example.com"
        provider.method = :get
        expect(provider).to be_valid
      end

      it "should be valid with minimal POST params" do
        provider.uri = "http://example.com"
        provider.method = :post
        provider.body = "<somexml></somexml>"
        expect(provider).to be_valid
      end

      it "should not be valid without a method" do
        provider.uri = "http://example.com"
        provider.method = nil
        expect(provider).not_to be_valid
        expect(provider.errors.first).to match /method/
      end

      it "should not be valid without a uri" do
        provider.uri = ""
        provider.method = :get
        expect(provider).not_to be_valid
        expect(provider.errors.first).to match /uri/
      end

      it "should require a body for post" do
        provider.uri = "http://example.com"
        provider.method = :post
        expect(provider).not_to be_valid
        expect(provider.errors.first).to match /body/
      end
    end

    describe "#client" do
      subject(:client) { provider.client }

      before { provider.uri = "http://example.com/" }

      it "should configure the base url" do
        expect(client.url.host).to eq "example.com"
      end

      it "returns the value of the passed block" do
        expect(provider.client { |http| "DATA" }).to eq "DATA"
      end
    end

    describe "#data" do
      let(:response)   { HTTPI::Response.new(200, {}, '{"success":true}') }

      subject(:provider) do
        Providers::HTTP.new do |s|
          s.uri    = "http://www.example.com/"
          s.query  = {username: "user"}
          s.method = :get
        end
      end

      it "returns string body on success" do
        expect(HTTPI).to receive(:request) { response }

        expect(provider.data).to eq '{"success":true}'
      end

      it "should setup basic auth if a username and password are supplied" do
        provider.username = "username"
        provider.password = "password"

        expect(HTTPI).to receive(:request) { response }
        expect_any_instance_of(HTTPI::Auth::Config).to receive(:basic).with("username", "password")

        expect(provider.data).to eq '{"success":true}'
      end
    end

  end
end

