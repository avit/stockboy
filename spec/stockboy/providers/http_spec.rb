require 'spec_helper'
require 'stockboy/providers/http'

module Stockboy
  describe Providers::HTTP do
    subject(:provider) { Stockboy::Providers::HTTP.new }

    it "should assign parameters from :uri option" do
      provider.uri    = "http://www.example.com/"
      provider.query  = {user: 'u'}
      provider.method = :get

      provider.uri.should    == URI("http://www.example.com/?user=u")
      provider.query.should  == {user: 'u'}
      provider.method.should == :get
    end

    it "should assign parameters from :get" do
      provider.get    = "http://www.example.com/"
      provider.query  = {user: 'u'}

      provider.uri.should    == URI("http://www.example.com/?user=u")
      provider.query.should  == {user: 'u'}
      provider.method.should == :get
    end

    it "should assign parameters from :post" do
      provider.post   = "http://www.example.com/"
      provider.query  = {user: 'u'}

      provider.uri.should    == URI("http://www.example.com/?user=u")
      provider.query.should  == {user: 'u'}
      provider.method.should == :post
    end

    it "should assign basic auth parameters" do
      provider.username = "username"
      provider.password = "password"

      provider.username.should == "username"
      provider.password.should == "password"
    end

    describe ".new" do
      its(:errors) { should be_empty }

      it "accepts block DSL initialization" do
        provider = Providers::HTTP.new do
          get    "http://www.example.com/"
          query  user: 'u'
        end

        provider.uri.should    == URI("http://www.example.com/?user=u")
        provider.query.should  == { user: 'u' }
        provider.method.should == :get
      end
    end

    describe "validation" do
      it "should not be valid without a method" do
        provider.uri = "http://example.com"
        provider.method = nil
        provider.should_not be_valid
        provider.errors.first.should match /method/
      end

      it "should not be valid without a uri" do
        provider.uri = ""
        provider.method = :get
        provider.should_not be_valid
        provider.errors.first.should match /uri/
      end
    end

    describe "#client" do
      subject(:client) { provider.client }

      before { provider.uri = "http://example.com/" }

      it "should configure the base url" do
        client.url.host.should == "example.com"
      end

      it "returns the value of the passed block" do
        provider.client { |http| "DATA" }.should == "DATA"
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

        provider.data.should == '{"success":true}'
      end

      it "should setup basic auth if a username and password are supplied" do
        provider.username = "username"
        provider.password = "password"

        expect(HTTPI).to receive(:request) { response }
        expect_any_instance_of(HTTPI::Auth::Config).to receive(:basic).with("username", "password")

        provider.data.should == '{"success":true}'
      end
    end

  end
end

