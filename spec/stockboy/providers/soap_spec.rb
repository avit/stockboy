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

      expect(provider.wsdl).to      eq "http://api.example.com/?wsdl"
      expect(provider.request).to   eq :get_user
      expect(provider.namespace).to eq "http://api.example.com/"
      expect(provider.message).to   eq({user: 'u', pass: 'p'})
      expect(provider.headers).to   eq({key: 'k'})
    end

    describe ".new" do
      its(:errors) { should be_empty }

      it "accepts block initialization" do
        provider = Providers::SOAP.new do |p|
          p.request   = :get_user
          p.endpoint  = "http://api.example.com/v1"
          p.namespace = "http://api.example.com/namespace"
          p.wsdl      = "http://api.example.com/?wsdl"
          p.open_timeout = 13
          p.read_timeout = 99
          p.message   = {user: 'u', pass: 'p'}
          p.headers   = {key: 'k'}
        end

        expect(provider.request).to   eq :get_user
        expect(provider.endpoint).to  eq "http://api.example.com/v1"
        expect(provider.wsdl).to      eq "http://api.example.com/?wsdl"
        expect(provider.client.globals[:open_timeout]).to eq 13
        expect(provider.client.globals[:read_timeout]).to eq 99
        expect(provider.namespace).to eq "http://api.example.com/namespace"
        expect(provider.message).to   eq({user: 'u', pass: 'p'})
        expect(provider.headers).to   eq({key: 'k'})
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
          expect(provider.errors.first).to match /endpoint/
        end
      end
    end

    describe "#client" do
      it "yields a Savon client" do
        provider.endpoint = "http://api.example.com/v1"
        provider.namespace = ''
        provider.client do |soap|
          expect(soap).to be_a Savon::Client
        end
      end
    end

    describe "#data" do
      let(:xml_success_fixture) do
        File.read(fixture_path "soap/get_list/success.xml")
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

      it "returns hash data on success by default" do
        should be_a Hash
      end

      it "returns xml data on success with an xml response_format" do
        provider.response_format = :xml
        should be_a String
      end

      it "uses string keys" do
        response.keys.each { |k| expect(k).to be_a String }
      end

      it "shares key string objects from a common pool" do
        cases = response["MultiNamespacedEntryResponse"]["history"]["case"]
        text_keys = cases.map { |c| c.keys[c.keys.index("logText")] }
        expect(text_keys[0]).to be text_keys[1]
      end

    end
  end
end
