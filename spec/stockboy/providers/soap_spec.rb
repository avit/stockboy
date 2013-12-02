require 'spec_helper'
require 'stockboy/providers/soap'

module Stockboy
  describe Providers::SOAP do
    before(:all) { savon.mock!   }
    after(:all)  { savon.unmock! }
    subject(:provider) { Stockboy::Providers::SOAP.new }

    it "should assign parameters" do
      provider.wsdl      = "http://api.example.com/?wsdl"
      provider.request   = :get_user
      provider.namespace = "http://api.example.com/"
      provider.message   = {user: 'u', pass: 'p'}
      provider.headers   = {key: 'k'}

      provider.wsdl.should      == "http://api.example.com/?wsdl"
      provider.request.should   == :get_user
      provider.namespace.should == "http://api.example.com/"
      provider.message.should   == {user: 'u', pass: 'p'}
      provider.headers.should   == {key: 'k'}
    end

    describe ".new" do
      its(:errors) { should be_empty }

      it "accepts block initialization" do
        provider = Providers::SOAP.new do |p|
          p.request   = :get_user
          p.endpoint  = "http://api.example.com/v1"
          p.namespace = "http://api.example.com/namespace"
          p.wsdl      = "http://api.example.com/?wsdl"
          p.message   = {user: 'u', pass: 'p'}
          p.headers   = {key: 'k'}
        end

        provider.request.should   == :get_user
        provider.endpoint.should  == "http://api.example.com/v1"
        provider.wsdl.should      == "http://api.example.com/?wsdl"
        provider.namespace.should == "http://api.example.com/namespace"
        provider.message.should   == {user: 'u', pass: 'p'}
        provider.headers.should   == {key: 'k'}
      end
    end

    describe "validation" do
      context "with a WSDL document" do
        before { provider.wsdl = "http://api.example.com/?wsdl" }
        it     { should be_valid }
      end

      context "without a WSDL document" do
        it "has error for blank endpoint & WSDL namespace" do
          provider.valid?
          provider.errors.keys.should include(:endpoint)
        end
      end
    end

    describe "#client" do
      it "yields a Savon client" do
        provider.endpoint = "http://api.example.com/v1"
        provider.namespace = ''
        provider.client do |soap|
          soap.should be_a Savon::Client
        end
      end
    end

    describe "#data" do
      let(:xml_success_fixture) do
        File.read(RSpec.configuration.fixture_path.join "soap/get_list/success.xml")
      end

      let(:provider) do
        Providers::SOAP.new do |s|
          s.endpoint = "http://api.example.com/v1"
          s.namespace = ''
          s.request = :get_list
          s.message = {username: "user", password: "pass"}
        end
      end

      subject(:response) do
        savon.expects(:get_list)
             .with(message: {username: 'user', password: 'pass'})
             .returns(xml_success_fixture)
        provider.data
      end

      it "returns hash data on success" do
        should be_a Hash
      end

      it "uses string keys" do
        response.keys.each { |k| k.should be_a String }
      end

      it "shares key string objects from a common pool" do
        cases = response["MultiNamespacedEntryResponse"]["history"]["case"]
        text_keys = cases.map { |c| c.keys[c.keys.index("logText")] }
        text_keys[0].should be text_keys[1]
      end

    end
  end
end
