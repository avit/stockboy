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
        expect(subject.config[:provider]).to be_a(provider_class)
      end

      it "registers with a class" do
        subject.provider provider_class
        expect(subject.config[:provider]).to be_a(provider_class)
      end

      it "initializes arguments" do
        expect(provider_class).to receive(:new).with(password:'foo')
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
        expect(subject.config[:reader]).to be_a(reader_class)
      end

      it "registers with a class" do
        subject.reader reader_class
        expect(subject.config[:reader]).to be_a(reader_class)
      end

      it "initializes arguments" do
        reader_stub = double(:reader)
        expect(reader_class).to receive(:new).with(col_sep: '|').and_return(reader_stub)
        subject.reader reader_class, col_sep: '|'
        expect(subject.config[:reader]).to eq reader_stub
      end
    end

    describe "#attributes" do
      it "initializes a block" do
        attribute_map = double
        expect(AttributeMap).to receive(:new).and_return(attribute_map)
        subject.attributes do end
        expect(subject.config[:attributes]).to be attribute_map
      end

      it "replaces existing attributes" do
        subject.attribute :first_name
        subject.attributes do last_name end
        expect(subject.config[:attributes][:first_name]).to be nil
        expect(subject.config[:attributes][:last_name]).to be_an Attribute
      end
    end

    describe "#attribute" do
      it "inserts a single attribute" do
        subject.attribute :test, from: "Test"
        expect(subject.config[:attributes][:test]).to eq Attribute.new(:test, "Test", [])
      end

      it "respects existing attributes added first" do
        subject.attributes do first_name end
        subject.attribute :last_name
        expect(subject.config[:attributes][:first_name]).to be_an Attribute
        expect(subject.config[:attributes][:last_name]).to be_an Attribute
      end
    end

    describe "#on" do

      let(:job) { double(:job, reset: true, process: true) }

      it "initializes a block" do
        subject.on :reprocess do |job, *args|
          job.reset
          job.process
        end

        expect(subject.config[:triggers][:reprocess][0]).to be_a Proc
      end

    end

    describe "#filter" do
      it "initializes a callable" do
        filter_stub = double(call: true)
        subject.filter :pass, filter_stub
        expect(subject.config[:filters][:pass]).to eq filter_stub
      end

      it "initializes a block" do
        subject.filter :pass do |r|
          true if r == 42
        end
        expect(subject.config[:filters][:pass].call(42)).to eq true
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
          expect(subject.config[:filters][:pass].args).to eq [42]
        end

        it "passes a block to a registered class symbol" do
          subject.filter :pass, :test do 42 end
          expect(subject.config[:filters][:pass].block[]).to eq 42
        end

        it "passes arguments to a given class" do
          subject.filter :pass, TestFilter, 42
          expect(subject.config[:filters][:pass].args).to eq [42]
        end

        it "uses an instance directly" do
          subject.filter :pass, TestFilter.new(42)
          expect(subject.config[:filters][:pass].args).to eq [42]
        end
      end

    end

    describe "#env" do
      it "returns a Hash" do
        expect(subject.env).to be_a(Hash)
      end

      it "raises an error when an undefined env variable is used" do
        expect{subject.env[:my_undefined_key]}.to raise_error DSLEnvVariableUndefined
      end

    end

    describe "#to_job" do
      before do
        Providers.register :test_prov, provider_class
        Readers.register :test_read, reader_class
        subject.provider :test_prov
        subject.reader :test_read
        subject.attributes do end
      end

      it "returns a Job instance" do
        job = subject.to_job
        expect(job).to be_a(Job)
        expect(job.provider).to be_a(provider_class)
        expect(job.reader).to be_a(reader_class)
        expect(job.attributes).to be_a(AttributeMap)
      end

      context "with a repeat block" do
        before do
          subject.repeat do |i, o| end
        end

        it "adds a repeater to the provider" do
          job = subject.to_job
          expect(job.provider).to be_a ProviderRepeater
          expect(job.provider.base_provider).to be_a provider_class
        end
      end
    end

  end
end
