require 'spec_helper'
require 'stockboy/providers/soap'

module Stockboy
  describe Providers::SOAP do
    let(:body_proc)   { proc { |req| req.user_id '123' } }
    let(:header_proc) { proc { |req| req.api_key '123' } }

    it "should assign parameters" do
      subject.wsdl_document = "http://api.example.com/?wsdl"
      subject.request       = :get_user, {xmlns: "http://api.example.com/"}
      subject.body          = body_proc
      subject.header        = header_proc

      subject.wsdl_document.should == "http://api.example.com/?wsdl"
      subject.request.should == [:get_user, xmlns: "http://api.example.com/"]
      subject.body.should == body_proc
      subject.header.should == header_proc
    end

    describe ".new" do
      its(:errors) { should be_empty }

      it "accepts block initialization" do
        subject = Providers::SOAP.new do |p|
          p.endpoint        = "http://api.example.com/v1"
          p.wsdl_namespace  = "http://api.example.com/namespace"
          p.wsdl_document   = "http://api.example.com/?wsdl"
          p.body &body_proc
        end

        subject.endpoint.should == "http://api.example.com/v1"
        subject.wsdl_document.should == "http://api.example.com/?wsdl"
        subject.wsdl_namespace.should == "http://api.example.com/namespace"
        subject.body.should == body_proc
      end
    end

    describe "validation" do
      context "with a WSDL document" do
        before { subject.wsdl_document = "http://api.example.com/?wsdl" }
        it     { should be_valid }
      end

      context "without a WSDL document" do
        it "has error for blank endpoint & WSDL namespace" do
          subject.valid?
          subject.errors.keys.should include(:endpoint)
        end
      end
    end

    describe "#data" do
      subject do
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
        response = subject.data

        response.should be_a Savon::SOAP::Response
        response.success?.should be_true
      end
    end
  end
end
