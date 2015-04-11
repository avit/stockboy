require 'spec_helper'
require 'stockboy/dsl'

module Stockboy
  describe DSL do

    class Dummy
      extend Stockboy::DSL
      dsl_attr :flag,        attr_writer: false
      dsl_attr :options
      dsl_attr :setter_only, attr_reader: false
      dsl_attr :undefined,   attr_accessor: false
    end

    let(:instance) { Dummy.new }
    subject(:dsl)  { Dummy::DSL.new(instance) }

    it "rejects assignment syntax when attr_writer is disabled" do
      expect { dsl.flag = :disable }.to raise_error NoMethodError
    end

    it "passes through to instance with no arguments" do
      expect(instance).to receive(:flag).with no_args
      dsl.flag
    end

    it "passes a value to writer with one argument" do
      expect(instance).to receive(:flag=).with :disable
      dsl.flag :disable
    end

    it "passes an array of values to writer with two arguments" do
      expect(instance).to receive(:options=).with [:one, :two]
      dsl.options :one, :two
    end

    it "passes through to writer with an array argument" do
      expect(instance).to receive(:options=).with [:one, :two]
      dsl.options [:one, :two]
    end

    it "requires assignment syntax when attr_reader is disabled" do
      expect { dsl.setter_only }.to raise_error NoMethodError
    end

    it "rejects both reader and writer syntax when attr_accessor is disabled" do
      expect { dsl.undefined }.to raise_error NoMethodError
      expect { dsl.undefined = :one }.to raise_error NoMethodError
    end

  end
end
