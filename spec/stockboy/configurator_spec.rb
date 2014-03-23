require 'spec_helper'
require 'stockboy/configurator'

module Stockboy
  describe Configurator do

    let(:provider_class) { OpenStruct }
    let(:reader_class)   { OpenStruct }

    describe "#initialize" do
      it "evaluates string config" do
        expect_any_instance_of(Configurator).to receive(:provider).with(:ftp)
        Configurator.new("provider :ftp")
      end

      it "evaluates block config" do
        expect_any_instance_of(Configurator).to receive(:provider).with(:ftp)
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

    describe "#repeat" do
      it "registers an enumerator block" do
        expect { subject.repeat }.to raise_error ArgumentError
        subject.repeat do |output, provider|
          output << provider
        end
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
        reader_stub = double(:reader)
        reader_class.should_receive(:new).with(col_sep: '|').and_return(reader_stub)
        subject.reader reader_class, col_sep: '|'
        subject.config[:reader].should == reader_stub
      end
    end

    describe "#attributes" do
      it "initializes a block" do
        attribute_map = double
        AttributeMap.should_receive(:new).and_return(attribute_map)
        subject.attributes &proc{}
        subject.config[:attributes].should be attribute_map
      end

      it "replaces existing attributes" do
        subject.attribute :first_name
        subject.attributes do last_name end
        subject.config[:attributes][:first_name].should be_nil
        subject.config[:attributes][:last_name].should be_an Attribute
      end
    end

    describe "#attribute" do
      it "inserts a single attribute" do
        subject.attribute :test, from: "Test"
        subject.config[:attributes][:test].should == Attribute.new(:test, "Test", [])
      end

      it "respects existing attributes added first" do
        subject.attributes do first_name end
        subject.attribute :last_name
        subject.config[:attributes][:first_name].should be_an Attribute
        subject.config[:attributes][:last_name].should be_an Attribute
      end
    end

    describe "#on" do

      let(:job) { double(:job, reset: true, process: true) }

      it "initializes a block" do
        subject.on :reprocess do |job, *args|
          job.reset
          job.process
        end

        subject.config[:triggers][:reprocess][0].should be_a Proc
      end

    end

    describe "#filter" do
      it "initializes a callable" do
        filter_stub = double(call: true)
        subject.filter :pass, filter_stub
        subject.config[:filters][:pass].should == filter_stub
      end

      it "initializes a block" do
        subject.filter :pass do |r|
          true if r == 42
        end
        subject.config[:filters][:pass].call(42).should == true
      end

      context "with a class" do
        class TestFilter
          attr_reader :args, :block
          def initialize(*args, &block)
            @args, @block = args, block
          end
        end
        before { Filters.register :test, TestFilter }

        it "passes arguments to a registered class symbol" do
          subject.filter :pass, :test, 42
          subject.config[:filters][:pass].args.should == [42]
        end

        it "passes a block to a registered class symbol" do
          subject.filter :pass, :test do 42 end
          subject.config[:filters][:pass].block[].should == 42
        end

        it "passes arguments to a given class" do
          subject.filter :pass, TestFilter, 42
          subject.config[:filters][:pass].args.should == [42]
        end

        it "uses an instance directly" do
          subject.filter :pass, TestFilter.new(42)
          subject.config[:filters][:pass].args.should == [42]
        end
      end

    end

    describe "#to_job" do
      before do
        Providers.register :test_prov, provider_class
        Readers.register :test_read, reader_class
        subject.provider :test_prov
        subject.reader :test_read
        subject.attributes &proc{}
      end

      it "returns a Job instance" do
        job = subject.to_job
        job.should be_a(Job)
        job.provider.should be_a(provider_class)
        job.reader.should be_a(reader_class)
        job.attributes.should be_a(AttributeMap)
      end

      context "with a repeat block" do
        before do
          subject.repeat do |i, o| end
        end

        it "adds a repeater to the provider" do
          job = subject.to_job
          job.provider.should be_a ProviderRepeater
          job.provider.base_provider.should be_a provider_class
        end
      end
    end

  end
end
