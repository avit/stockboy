require 'spec_helper'
require 'stockboy/providers/soap'

module Stockboy
  describe Providers::SOAP do

    subject(:soap) { Stockboy::Providers::SOAP.new }

    it "should assign parameters" do
      body_proc = proc { |req| req.user_id '123' }
      header_proc = proc { |req| req.api_key '123' }

      soap.wsdl_document = "http://api.example.com/?wsdl"
      soap.request       = :get_user, {xmlns: "http://api.example.com/"}
      soap.body          = body_proc
      soap.header        = header_proc

      soap.wsdl_document.should == "http://api.example.com/?wsdl"
      soap.request.should == [:get_user, xmlns: "http://api.example.com/"]
      soap.body.should == body_proc
      soap.header.should == header_proc
    end

    describe ".new" do
      its(:errors) { should be_empty }

      it "accepts block initialization" do
        body_proc = proc { |req| req.api_key '123' }

        soap = Providers::SOAP.new do |p|
          p.endpoint        = "http://api.example.com/v1"
          p.wsdl_namespace  = "http://api.example.com/namespace"
          p.wsdl_document   = "http://api.example.com/?wsdl"
          p.body &body_proc
        end

        soap.endpoint.should == "http://api.example.com/v1"
        soap.wsdl_document.should == "http://api.example.com/?wsdl"
        soap.wsdl_namespace.should == "http://api.example.com/namespace"
        soap.body.should == body_proc
      end
    end

    describe "validation" do
      context "with a WSDL document" do
        before { soap.wsdl_document = "http://api.example.com/?wsdl" }
        it     { should be_valid }
      end

      context "without a WSDL document" do
        it "has error for blank endpoint & WSDL namespace" do
          soap.valid?
          soap.errors.keys.should include(:endpoint)
        end
      end
    end

    describe "#data" do
      subject(:soap) do
        Providers::SOAP.new do |s|
          s.endpoint = "http://api.example.com/v1"
          s.wsdl_namespace = ''
          s.request = [:get_list]
          s.body do |req|
            req.username "user"
            req.password "pass"
          end
        end
      end

      it "returns hash data on success" do
        savon.expects(:get_list)
             .with("<username>user</username><password>pass</password>")
             .returns(:success)
        response = soap.data

        response.should be_a Savon::SOAP::Response
        response.success?.should be_true
      end
    end
  end
end
