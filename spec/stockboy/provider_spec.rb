require 'spec_helper'
require 'stockboy/provider'

class ProviderSubclass < Stockboy::Provider
  attr_accessor :foo
  def validate
    errors.add_on_empty(:foo, "Foo is empty")
  end
end

module Stockboy
  describe Provider do

    describe "#errors" do
      its(:errors) { should be_empty }
    end

    describe "#stats" do
      its(:stats) { should be_empty }
    end

    describe "#logger" do
      its(:logger) { should respond_to :error }
    end

    describe "abstract method" do
      subject { Class.new(Provider).new }

      it "raises error for unimplemented #validate" do
        expect{ subject.send :validate }.to raise_error(NoMethodError)
      end

      it "raises error for unimplemented #fetch_data" do
        expect{ subject.send :fetch_data }.to raise_error(NoMethodError)
      end
    end
  end
end
