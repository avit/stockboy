require 'spec_helper'
require 'stockboy/configurator'

module Stockboy
  describe Configurator do

    let(:provider_class) { OpenStruct }
    let(:reader_class)   { OpenStruct }

    describe "#initialize" do
      it "evaluates string config" do
        Configurator.any_instance.should_receive(:provider).with(:ftp)
        Configurator.new("provider :ftp")
      end

      it "evaluates block config" do
        Configurator.any_instance.should_receive(:provider).with(:ftp)
        Configurator.new do
          provider :ftp
        end
      end
    end

    describe "#provider" do
      before do
        Providers.register(:ftp, provider_class)
      end

      it "registers with a symbol" do
        subject.provider :ftp
        subject.config[:provider].should be_a(provider_class)
      end

      it "registers with a class" do
        subject.provider provider_class
        subject.config[:provider].should be_a(provider_class)
      end

      it "initializes arguments" do
        provider_class.should_receive(:new).with(password:'foo')
        subject.provider :ftp, password: 'foo'
      end
    end

    describe "#reader" do
      before do
        Readers.register(:csv, reader_class)
      end

      it "registers with a symbol" do
        subject.reader :csv
        subject.config[:reader].should be_a(reader_class)
      end

      it "registers with a class" do
        subject.reader reader_class
        subject.config[:reader].should be_a(reader_class)
      end

      it "initializes arguments" do
        reader_stub = stub(:reader)
        reader_class.should_receive(:new).with(col_sep: '|').and_return(reader_stub)
        subject.reader reader_class, col_sep: '|'
        subject.config[:reader].should == reader_stub
      end
    end

    describe "#attributes" do
      it "initializes a block" do
        attribute_map = stub
        AttributeMap.should_receive(:new).and_return(attribute_map)
        subject.attributes &proc{}
        subject.config[:attributes].should be attribute_map
      end
    end

    describe "#filter" do
      it "initializes a callable" do
        filter_stub = stub(call: true)
        subject.filter :pass, filter_stub
        subject.config[:filters][:pass].should == filter_stub
      end

      it "initializes a block" do
        subject.filter :pass do |r|
          true if r == 42
        end
        subject.config[:filters][:pass].call(42).should == true
      end
    end

    describe "#to_job" do
      before do
        Providers.register :test_prov, provider_class
        Readers.register :test_read, reader_class
      end

      it "returns a Job instance" do
        subject.provider :test_prov
        subject.reader :test_read
        subject.attributes &proc{}

        job = subject.to_job
        job.should be_a(Job)
        job.provider.should be_a(provider_class)
        job.reader.should be_a(reader_class)
        job.attributes.should be_a(AttributeMap)
      end
    end

  end
end
